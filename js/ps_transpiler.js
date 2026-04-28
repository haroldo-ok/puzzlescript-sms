'use strict';

/**
 * PuzzleScript → Sega Master System ROM Transpiler
 *
 * Strategy: "offline simulation"
 *   We run the PuzzleScript engine itself (already loaded on the page) against
 *   each compiled level.  Starting from the initial state, we perform a BFS
 *   over all reachable game states, recording the (state, input) → nextState
 *   transition for every input direction.  We also record which states satisfy
 *   the win conditions.  All of this is baked into resource files that the
 *   new ps_base_rom.sms can load and interpret directly on Z80 hardware.
 *
 * Resource files written:
 *   ps.pal  - 16-byte SMS palette
 *   ps.til  - SMS tile data (4 SMS tiles per PS object, each 32 bytes)
 *   ps.lvl  - Level cell data for every reachable state of every level
 *   ps.trn  - Transition tables
 *   ps.win  - Encoded in ps.trn (win byte per state)
 *   ps.inf  - Project name (null-terminated string)
 *
 * Limits:
 *   Max 512 reachable states per level (SMS RAM constraint).
 *   Max 16×9 tiles per level (screen constraint).
 *   Max 60 distinct objects (tile memory constraint: 4 SMS tiles each,
 *     60×4=240 tiles + 4 blank = 244 tiles < 448 available).
 */

(function () {

    // ─────────────────────────────────────────────────────────────────────────
    // Utility
    // ─────────────────────────────────────────────────────────────────────────

    const MAX_STATES_PER_LEVEL = 512;
    const TILE_INPUTS = [0, 1, 2, 3, 4]; // up, left, down, right, action
    const INPUT_NAMES = ['up', 'left', 'down', 'right', 'action'];

    function flatten(arr) {
        return arr.reduce((a, b) => a.concat(Array.isArray(b) ? flatten(b) : b), []);
    }

    function u16le(n) {
        n = n & 0xFFFF;
        return [n & 0xFF, (n >> 8) & 0xFF];
    }

    // ─────────────────────────────────────────────────────────────────────────
    // SMS palette / tile helpers  (shared with sms_export.js approach)
    // ─────────────────────────────────────────────────────────────────────────

    function toSms2bit(ch) { return Math.round(ch / 85); }

    function hexToRgb(hex) {
        hex = hex.replace(/^#/, '');
        if (hex.length === 3) hex = hex.split('').map(c => c + c).join('');
        return {
            r: parseInt(hex.slice(0, 2), 16),
            g: parseInt(hex.slice(2, 4), 16),
            b: parseInt(hex.slice(4, 6), 16)
        };
    }

    function rgbToSmsByte(r, g, b) {
        return toSms2bit(r) | (toSms2bit(g) << 2) | (toSms2bit(b) << 4);
    }

    function quantiseRgb(r, g, b) {
        return { r: toSms2bit(r) * 85, g: toSms2bit(g) * 85, b: toSms2bit(b) * 85 };
    }

    function colDist2(r1, g1, b1, r2, g2, b2) {
        return (r1-r2)**2 + (g1-g2)**2 + (b1-b2)**2;
    }

    function nearestPalIdx(r, g, b, palRgb) {
        let best = 0, bestD = Infinity;
        for (let i = 0; i < palRgb.length; i++) {
            const p = palRgb[i];
            const d = colDist2(r, g, b, p.r, p.g, p.b);
            if (d < bestD) { bestD = d; best = i; }
        }
        return best;
    }

    /** Upscale a 5×5 PuzzleScript sprite to 16×16 pixel grid */
    function upscaleSprite(obj) {
        const SRC = 5, DST = 16;
        const resolved = obj.colors.map(c => {
            if (!c || c === 'transparent') return null;
            try { return hexToRgb(c.trim()); } catch(e) { return null; }
        });
        const pixels = [];
        for (let ty = 0; ty < DST; ty++) {
            const sy = Math.floor(ty * SRC / DST);
            const row = [];
            for (let tx = 0; tx < DST; tx++) {
                const sx = Math.floor(tx * SRC / DST);
                const idx = obj.spritematrix[sy] !== undefined ? obj.spritematrix[sy][sx] : -1;
                if (idx < 0 || idx >= resolved.length || !resolved[idx]) row.push(null);
                else row.push([resolved[idx].r, resolved[idx].g, resolved[idx].b]);
            }
            pixels.push(row);
        }
        return pixels;
    }

    /** Build a 16-entry SMS palette from all sprites */
    function buildPalette(tilePixels, bgColor) {
        const colorSet = new Map();
        let bgRgb = { r: 0, g: 0, b: 0 };
        if (bgColor) {
            try { const c = hexToRgb(bgColor); bgRgb = quantiseRgb(c.r, c.g, c.b); } catch(e) {}
        }
        const bgKey = `${bgRgb.r},${bgRgb.g},${bgRgb.b}`;
        colorSet.set(bgKey, { sms: rgbToSmsByte(bgRgb.r, bgRgb.g, bgRgb.b), rgb: bgRgb });

        for (const pixels of tilePixels) {
            for (const row of pixels) {
                for (const px of row) {
                    if (!px) continue;
                    const q = quantiseRgb(px[0], px[1], px[2]);
                    const key = `${q.r},${q.g},${q.b}`;
                    if (!colorSet.has(key))
                        colorSet.set(key, { sms: rgbToSmsByte(q.r, q.g, q.b), rgb: q });
                }
            }
        }
        const entries = [...colorSet.values()].slice(0, 16);
        const palette = entries.map(e => e.sms);
        const palRgb  = entries.map(e => e.rgb);
        while (palette.length < 16) { palette.push(0); palRgb.push({r:0,g:0,b:0}); }
        return { palette, palRgb };
    }

    /**
     * Encode one 16×16 sprite as 4 SMS 8×8 tiles (128 bytes total).
     * Layout: TL, TR, BL, BR (matching ps_rom.c draw_board).
     */
    function encodeTile16(pixels, palRgb) {
        const quads = [
            {ox:0, oy:0}, {ox:8, oy:0},
            {ox:0, oy:8}, {ox:8, oy:8}
        ];
        const result = [];
        for (const {ox, oy} of quads) {
            for (let row = 0; row < 8; row++) {
                const planes = [0,0,0,0];
                for (let col = 0; col < 8; col++) {
                    const px = pixels[oy+row][ox+col];
                    let pidx;
                    if (!px) {
                        pidx = 0;
                    } else {
                        const q = quantiseRgb(px[0], px[1], px[2]);
                        pidx = nearestPalIdx(q.r, q.g, q.b, palRgb);
                    }
                    const bit = 0x80 >> col;
                    for (let p = 0; p < 4; p++) {
                        if (pidx & (1 << p)) planes[p] |= bit;
                    }
                }
                result.push(...planes);
            }
        }
        return result; // 128 bytes
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Level state serialisation
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Snapshot the current PuzzleScript level as a flat Uint8Array of object IDs.
     * Each cell holds the *topmost* non-background object's 1-based index in
     * objectList, or 0 if empty / background.
     */
    function snapshotLevel(levelObj, objectList, bgId, w, h) {
        const snap = new Uint8Array(w * h);
        const objById = {};
        objectList.forEach((name, i) => {
            const obj = state.objects[name];
            if (obj) objById[obj.id] = i + 1; // 1-based
        });

        for (let col = 0; col < w; col++) {
            for (let row = 0; row < h; row++) {
                const cellIdx = col * h + row;
                const wordBase = cellIdx * state.STRIDE_OBJ;
                let topObj = 0;
                // Walk layers top to bottom
                for (let layer = state.LAYER_COUNT - 1; layer >= 0; layer--) {
                    for (const name of Object.keys(state.objects)) {
                        const obj = state.objects[name];
                        if (obj.layer !== layer || obj.id === bgId) continue;
                        const word = levelObj.objects[wordBase + Math.floor(obj.id / 32)];
                        if (word & (1 << (obj.id % 32))) {
                            topObj = objById[obj.id] || 0;
                            break;
                        }
                    }
                    if (topObj) break;
                }
                snap[col + row * w] = topObj; // row-major for the ROM
            }
        }
        return snap;
    }

    function snapKey(snap) {
        return snap.join(',');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Win condition check
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Test whether the current `level` global satisfies state.winconditions.
     * We replicate checkWin() logic without side effects.
     */
    function testWin() {
        if (!state.winconditions || state.winconditions.length === 0) return false;

        for (const wc of state.winconditions) {
            const [mode, filter1, filter2, , aggr1, aggr2] = wc;
            const f1 = aggr1 ? c => filter1.bitsSetInArray(c) : c => !filter1.bitsClearInArray(c);
            const f2 = aggr2 ? c => filter2.bitsSetInArray(c) : c => !filter2.bitsClearInArray(c);
            let rulePassed = true;

            if (mode === -1) { // NO
                for (let i = 0; i < level.n_tiles; i++) {
                    level.getCellInto(i, _o10);
                    if (f1(_o10.data) && f2(_o10.data)) { rulePassed = false; break; }
                }
            } else if (mode === 0) { // SOME
                let any = false;
                for (let i = 0; i < level.n_tiles; i++) {
                    level.getCellInto(i, _o10);
                    if (f1(_o10.data) && f2(_o10.data)) { any = true; break; }
                }
                if (!any) rulePassed = false;
            } else { // ALL
                for (let i = 0; i < level.n_tiles; i++) {
                    level.getCellInto(i, _o10);
                    if (f1(_o10.data) && !f2(_o10.data)) { rulePassed = false; break; }
                }
            }
            if (!rulePassed) return false;
        }
        return true;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // BFS state enumeration per level
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Given a compiled PuzzleScript level index, enumerate all reachable states
     * via BFS.  For each state, simulate all 5 inputs using processInput().
     *
     * Returns:
     *   { width, height, states: Uint8Array[], transitions: [{next:[5], win}] }
     *
     * states[i] is the board snapshot for state i (Uint8Array, row-major).
     * transitions[i].next[dir] = index of next state (0xFFFF = no change).
     * transitions[i].win = 1 if state i satisfies win conditions.
     */
    function enumerateLevel(levelIndex, objectList, bgId) {
        const levelDat = state.levels[levelIndex];
        if (!levelDat || levelDat.message !== undefined) return null;

        const w = levelDat.width;
        const h = levelDat.height;

        // State registry: snapshot string → index
        const stateMap = new Map();
        const states = [];       // array of Uint8Array snapshots
        const transitions = [];  // array of {next:[5 ints], win:0|1}

        // Helper: save current `level` global as a new state entry, return index
        function registerCurrentState() {
            const snap = snapshotLevel(level, objectList, bgId, w, h);
            const key  = snapKey(snap);
            if (stateMap.has(key)) return stateMap.get(key);
            const idx = states.length;
            stateMap.set(key, idx);
            states.push(snap);
            transitions.push({ next: [0xFFFF,0xFFFF,0xFFFF,0xFFFF,0xFFFF], win: 0 });
            return idx;
        }

        // Helper: save / restore the Int32Array backing of `level.objects`
        function saveLevel() { return new Int32Array(level.objects); }
        function restoreLevel(saved) {
            level.objects = new Int32Array(saved);
            level.movements = new Int32Array(level.n_tiles * STRIDE_MOV);
            // Reset row/col masks
            state.calculateRowColMasks(level);
        }

        // Load the initial level state
        loadLevelFromState(state, levelIndex, 'transpile-seed');
        const initialSnap = registerCurrentState();

        const queue = [0]; // BFS queue of state indices
        let qi = 0;

        while (qi < queue.length) {
            if (states.length >= MAX_STATES_PER_LEVEL) {
                logError(`SMS Export: Level ${levelIndex+1} has >${MAX_STATES_PER_LEVEL} reachable states; truncating. Some transitions may be missing.`, 0);
                break;
            }

            const stateIdx = queue[qi++];
            const snap = states[stateIdx];

            // Restore the level to this state's board
            loadLevelFromState(state, levelIndex, 'transpile-seed');
            // Overwrite the level objects from snapshot
            _applySnapToLevel(snap, w, h, objectList, bgId);
            state.calculateRowColMasks(level);

            // Check win for this state
            transitions[stateIdx].win = testWin() ? 1 : 0;

            // Try each input
            for (let dir = 0; dir < 5; dir++) {
                // Save current state
                const saved = saveLevel();
                // Apply input via PS engine (no-win, no-modify side effects)
                const prevWinning = winning;
                const prevAgaining = againing;
                winning = false;
                againing = false;

                // processInput handles rules, movements, commands
                processInput(dir, /*dontDoWin=*/true, /*dontModify=*/false);

                winning = prevWinning;
                againing = prevAgaining;

                // Snapshot result
                const resultSnap = snapshotLevel(level, objectList, bgId, w, h);
                const resultKey  = snapKey(resultSnap);
                const initialKey = snapKey(snap);

                if (resultKey === initialKey) {
                    // No change — input was blocked / no-op
                    transitions[stateIdx].next[dir] = 0xFFFF;
                } else {
                    let resultIdx;
                    if (stateMap.has(resultKey)) {
                        resultIdx = stateMap.get(resultKey);
                    } else {
                        resultIdx = states.length;
                        stateMap.set(resultKey, resultIdx);
                        states.push(resultSnap);
                        transitions.push({ next:[0xFFFF,0xFFFF,0xFFFF,0xFFFF,0xFFFF], win:0 });
                        queue.push(resultIdx);
                    }
                    transitions[stateIdx].next[dir] = resultIdx;
                }

                // Restore before next input trial
                restoreLevel(saved);
            }
        }

        return { width: w, height: h, states, transitions };
    }

    /**
     * Apply a snapshot back into the live `level` object so processInput can run.
     * This reverses snapshotLevel: for each cell, we set exactly the objects
     * present in the snapshot (plus background on its layer).
     */
    function _applySnapToLevel(snap, w, h, objectList, bgId) {
        // Zero out all objects
        level.objects.fill(0);
        level.movements = new Int32Array(level.n_tiles * STRIDE_MOV);

        // Always set background everywhere
        if (bgId >= 0) {
            for (let col = 0; col < w; col++) {
                for (let row = 0; row < h; row++) {
                    const cellIdx = col * h + row;
                    const wordBase = cellIdx * state.STRIDE_OBJ;
                    level.objects[wordBase + Math.floor(bgId / 32)] |= (1 << (bgId % 32));
                }
            }
        }

        // Set each non-background object from snapshot
        for (let row = 0; row < h; row++) {
            for (let col = 0; col < w; col++) {
                const snapVal = snap[col + row * w]; // 1-based object index
                if (!snapVal) continue;
                const objName = objectList[snapVal - 1];
                if (!objName) continue;
                const obj = state.objects[objName];
                if (!obj) continue;
                const cellIdx = col * h + row;
                const wordBase = cellIdx * state.STRIDE_OBJ;
                level.objects[wordBase + Math.floor(obj.id / 32)] |= (1 << (obj.id % 32));
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Resource filesystem builder (identical to SMS-Puzzle-Maker)
    // ─────────────────────────────────────────────────────────────────────────

    function padEnd(arr, len, val) {
        const a = arr.slice();
        while (a.length < len) a.push(val);
        return a;
    }
    function strBytes(s) { return [...s].map(c => c.charCodeAt(0)).concat([0]); }

    function buildFileSystem(files) {
        const PAGE_SIZE = 16 * 1024;
        const INITIAL_PAGE = 2;
        const ENTRY_SIZE = 14 + 2 + 2 + 2; // name(14) + page(2) + size(2) + offset(2)

        const entries = Object.keys(files).sort().map(n => ({ name: n, data: files[n] }));
        const header = [...strBytes('rsc').slice(0,4), 0, ...u16le(entries.length)].slice(0,6);
        // rsc\0 = 4 bytes + u16 count = 6 bytes
        const headerBytes = [
            'r'.charCodeAt(0), 's'.charCodeAt(0), 'c'.charCodeAt(0), 0,
            ...u16le(entries.length)
        ];
        const tableSize = entries.length * ENTRY_SIZE;
        let fileOffset = headerBytes.length + tableSize;

        let page = INITIAL_PAGE;
        const allocated = entries.map(e => {
            if (fileOffset + e.data.length > PAGE_SIZE) { page++; fileOffset = 0; }
            const entry = { name: e.name, page, offset: fileOffset, data: e.data };
            fileOffset += e.data.length;
            return entry;
        });

        const table = flatten(allocated.map(e => {
            const nameBytes = padEnd([...e.name].map(c => c.charCodeAt(0)), 14, 0);
            return [...nameBytes, ...u16le(e.page), ...u16le(e.data.length), ...u16le(e.offset)];
        }));

        const pages = [[...headerBytes, ...table]];
        allocated.forEach(({ page: pg, offset, data }) => {
            const pi = pg - INITIAL_PAGE;
            if (!pages[pi]) pages[pi] = new Array(PAGE_SIZE).fill(0);
            const p = pages[pi];
            while (p.length < PAGE_SIZE) p.push(0);
            data.forEach((b, i) => { p[offset + i] = b; });
        });

        return flatten(pages);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Main export entry point
    // ─────────────────────────────────────────────────────────────────────────

    window.exportToPsRom = function () {
        try {
            if (!state || !state.objects || !state.levels || state.levels.length === 0) {
                logError('Please compile a game before exporting to SMS ROM.', 0);
                return;
            }

            consolePrint('[SMS Export] Starting transpilation…');

            // ── 1. Build object list (sorted by id, skip background) ──────────
            const bgName = 'background';
            const bgId   = state.objects[bgName] ? state.objects[bgName].id : -1;

            const objectList = Object.keys(state.objects)
                .filter(n => n !== bgName && state.objects[n].spritematrix && state.objects[n].colors)
                .sort((a, b) => state.objects[a].id - state.objects[b].id);

            if (objectList.length > 60) {
                logError('SMS Export: game has more than 60 objects; only the first 60 will be exported.', 0);
                objectList.length = 60;
            }

            // ── 2. Build SMS palette & tile data ──────────────────────────────
            const tilePixels = objectList.map(n => upscaleSprite(state.objects[n]));
            const { palette, palRgb } = buildPalette(tilePixels, state.bgcolor);

            // Tile 0 = blank (128 zero bytes)
            const tilBytes = new Array(128).fill(0);
            tilePixels.forEach(px => tilBytes.push(...encodeTile16(px, palRgb)));

            // ── 3. Enumerate all reachable states per level ───────────────────
            const gameLevels = state.levels
                .map((ld, i) => ({ ld, i }))
                .filter(({ ld }) => ld.message === undefined);

            if (gameLevels.length === 0) {
                logError('SMS Export: no playable levels found.', 0);
                return;
            }

            consolePrint(`[SMS Export] Enumerating states for ${gameLevels.length} level(s)…`);

            const levelResults = gameLevels.map(({ ld, i }) => {
                consolePrint(`[SMS Export]   Level ${i+1}: w=${ld.width} h=${ld.height}`);
                const result = enumerateLevel(i, objectList, bgId);
                if (!result) return null;
                consolePrint(`[SMS Export]   → ${result.states.length} reachable states`);
                return result;
            }).filter(Boolean);

            // ── 4. Encode ps.lvl ──────────────────────────────────────────────
            // u16 levelCount
            // for each level:
            //   u16 width, u16 height, u16 stateCount
            //   u8[width*height] × stateCount  (all state cell data)
            const lvlBytes = [...u16le(levelResults.length)];
            for (const lr of levelResults) {
                lvlBytes.push(...u16le(lr.width));
                lvlBytes.push(...u16le(lr.height));
                lvlBytes.push(...u16le(lr.states.length));
                for (const snap of lr.states) {
                    for (let i = 0; i < snap.length; i++) lvlBytes.push(snap[i]);
                }
            }

            // ── 5. Encode ps.trn ──────────────────────────────────────────────
            // for each level:
            //   u16 stateCount
            //   for each state:
            //     u16×5 next[5]   (0xFFFF = no change)
            //     u8    win
            const trnBytes = [];
            for (const lr of levelResults) {
                trnBytes.push(...u16le(lr.states.length));
                for (const t of lr.transitions) {
                    for (let d = 0; d < 5; d++) trnBytes.push(...u16le(t.next[d]));
                    trnBytes.push(t.win ? 1 : 0);
                }
            }

            // ── 6. ps.inf ─────────────────────────────────────────────────────
            const projName = (state.metadata && state.metadata.title) || 'PuzzleScript';
            const infBytes = strBytes(projName);

            // ── 7. Build resource filesystem ──────────────────────────────────
            const files = {
                'ps.pal': padEnd(palette, 16, 0),
                'ps.til': tilBytes,
                'ps.lvl': lvlBytes,
                'ps.trn': trnBytes,
                'ps.inf': infBytes
            };
            const resourceData = buildFileSystem(files);
            const resourceBlob = new Blob([new Uint8Array(resourceData)],
                { type: 'application/octet-stream' });

            // ── 8. Fetch new base ROM and append resource data ─────────────────
            fetch('base-rom/ps_base_rom.sms')
                .then(r => {
                    if (!r.ok) throw new Error('Could not load ps_base_rom.sms (HTTP ' + r.status + ')');
                    return r.blob();
                })
                .then(baseBlob => {
                    const finalBlob = new Blob([baseBlob, resourceBlob],
                        { type: 'application/octet-stream' });
                    const safeName = projName.replace(/[^A-Za-z0-9]/g, '_').replace(/_+/g, '_');
                    saveAs(finalBlob, safeName + '_ps.sms');
                    consolePrint(`[SMS Export] Done! ROM saved as ${safeName}_ps.sms`);
                    consolePrint(`[SMS Export] Levels: ${levelResults.length}, Objects: ${objectList.length}`);
                })
                .catch(err => {
                    logError('SMS ROM export failed: ' + err.message, 0);
                    console.error('[SMS Export]', err);
                });

        } catch (err) {
            logError('SMS ROM export error: ' + err.message, 0);
            console.error('[SMS Export]', err);
        }
    };

})();
