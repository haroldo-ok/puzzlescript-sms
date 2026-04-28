'use strict';

/**
 * PuzzleScript → SMS Transpiler  (v2)
 *
 * Enumerates all reachable game states by running the PuzzleScript engine
 * in-browser, then packs them into a resource block for ps_base_rom.sms.
 *
 * saveAs() in this codebase: saveAs(content, mimeType, filename)
 *   where content is a Uint8Array/ArrayBuffer.
 */

(function () {

    // ── Limits ────────────────────────────────────────────────────────────────
    const MAX_STATES_PER_LEVEL = 256;  // must match C ROM MAX_STATES

    // ── Binary helpers ────────────────────────────────────────────────────────
    function u16le(n) {
        n = n >>> 0;
        return [(n & 0xFF), ((n >> 8) & 0xFF)];
    }

    // ── SMS palette / tile helpers ────────────────────────────────────────────
    function toSms2(ch)       { return Math.round(ch / 85); }
    function hexToRgb(hex)    {
        hex = hex.replace(/^#/, '');
        if (hex.length === 3) hex = hex.split('').map(c => c+c).join('');
        return { r: parseInt(hex.slice(0,2),16), g: parseInt(hex.slice(2,4),16), b: parseInt(hex.slice(4,6),16) };
    }
    function quantise(r,g,b)  { return { r: toSms2(r)*85, g: toSms2(g)*85, b: toSms2(b)*85 }; }
    function smsByte(r,g,b)   { return toSms2(r) | (toSms2(g)<<2) | (toSms2(b)<<4); }
    function dist2(r1,g1,b1,r2,g2,b2) { return (r1-r2)**2+(g1-g2)**2+(b1-b2)**2; }

    function nearestPal(r,g,b, palRgb) {
        let best=0, bestD=Infinity;
        for (let i=0; i<palRgb.length; i++) {
            const p=palRgb[i], d=dist2(r,g,b,p.r,p.g,p.b);
            if (d<bestD) { bestD=d; best=i; }
        }
        return best;
    }

    function upscaleSprite(obj) {
        const SRC=5, DST=16;
        const res = obj.colors.map(c => {
            if (!c || c==='transparent') return null;
            try { return hexToRgb(c.trim()); } catch(e) { return null; }
        });
        return Array.from({length:DST}, (_,ty) => {
            const sy = Math.floor(ty*SRC/DST);
            return Array.from({length:DST}, (_,tx) => {
                const sx = Math.floor(tx*SRC/DST);
                const idx = obj.spritematrix[sy]?.[sx] ?? -1;
                if (idx<0 || !res[idx]) return null;
                return [res[idx].r, res[idx].g, res[idx].b];
            });
        });
    }

    function buildPalette(tilePixels, bgColor) {
        const map = new Map();
        let bgRgb = {r:0,g:0,b:0};
        if (bgColor) { try { const c=hexToRgb(bgColor); bgRgb=quantise(c.r,c.g,c.b); } catch(e){} }
        const addColor = (r,g,b) => {
            const q=quantise(r,g,b), k=`${q.r},${q.g},${q.b}`;
            if (!map.has(k)) map.set(k, { sms:smsByte(q.r,q.g,q.b), rgb:q });
        };
        addColor(bgRgb.r, bgRgb.g, bgRgb.b);
        for (const pixels of tilePixels)
            for (const row of pixels)
                for (const px of row)
                    if (px) addColor(px[0],px[1],px[2]);
        const entries = [...map.values()].slice(0,16);
        const palette = entries.map(e=>e.sms);
        const palRgb  = entries.map(e=>e.rgb);
        while (palette.length<16) { palette.push(0); palRgb.push({r:0,g:0,b:0}); }
        return {palette, palRgb};
    }

    function encodeTile16(pixels, palRgb) {
        // 16×16 → 4 SMS 8×8 tiles: TL,TR,BL,BR (128 bytes)
        const quads = [{ox:0,oy:0},{ox:8,oy:0},{ox:0,oy:8},{ox:8,oy:8}];
        const out = [];
        for (const {ox,oy} of quads) {
            for (let row=0; row<8; row++) {
                const planes=[0,0,0,0];
                for (let col=0; col<8; col++) {
                    const px=pixels[oy+row][ox+col];
                    let pidx=0;
                    if (px) { const q=quantise(px[0],px[1],px[2]); pidx=nearestPal(q.r,q.g,q.b,palRgb); }
                    const bit=0x80>>col;
                    for (let p=0; p<4; p++) if (pidx&(1<<p)) planes[p]|=bit;
                }
                out.push(...planes);
            }
        }
        return out;
    }

    // ── State snapshot ────────────────────────────────────────────────────────
    // Returns a Uint8Array[w*h]: each cell = 1-based object index (0=bg/empty)
    function snapshot(w, h, objectList, bgId) {
        const snap = new Uint8Array(w*h);
        // Build id→listIndex map
        const byId = {};
        objectList.forEach((name,i) => {
            const obj = state.objects[name];
            if (obj) byId[obj.id] = i+1;
        });
        for (let col=0; col<w; col++) {
            for (let row=0; row<h; row++) {
                const ci = col*h + row;  // PS column-major
                const wb = ci * state.STRIDE_OBJ;
                let top = 0;
                // Highest layer wins
                outer:
                for (let layer=state.LAYER_COUNT-1; layer>=0; layer--) {
                    for (const name of Object.keys(state.objects)) {
                        const obj = state.objects[name];
                        if (obj.layer !== layer || obj.id === bgId) continue;
                        const word = level.objects[wb + Math.floor(obj.id/32)];
                        if (word & (1<<(obj.id%32))) {
                            top = byId[obj.id] || 0;
                            break outer;
                        }
                    }
                }
                snap[col + row*w] = top;  // row-major for the ROM
            }
        }
        return snap;
    }

    function snapKey(s) { return s.join(','); }

    // ── Apply snapshot back into live `level` ─────────────────────────────────
    function applySnap(snap, w, h, objectList, bgId) {
        level.objects.fill(0);
        level.movements.fill(0);
        // Always place background
        if (bgId >= 0) {
            for (let col=0; col<w; col++) {
                for (let row=0; row<h; row++) {
                    const ci = col*h+row, wb = ci*state.STRIDE_OBJ;
                    level.objects[wb + Math.floor(bgId/32)] |= (1<<(bgId%32));
                }
            }
        }
        // Place foreground objects
        for (let row=0; row<h; row++) {
            for (let col=0; col<w; col++) {
                const val = snap[col + row*w];
                if (!val) continue;
                const name = objectList[val-1];
                if (!name) continue;
                const obj = state.objects[name];
                if (!obj) continue;
                const ci = col*h+row, wb = ci*state.STRIDE_OBJ;
                level.objects[wb + Math.floor(obj.id/32)] |= (1<<(obj.id%32));
            }
        }
        state.calculateRowColMasks(level);
    }

    // ── Win test (no side effects) ────────────────────────────────────────────
    function testWin() {
        if (!state.winconditions || state.winconditions.length === 0) return false;
        for (const wc of state.winconditions) {
            const [mode, f1, f2, , aggr1, aggr2] = wc;
            const chk1 = aggr1 ? c=>f1.bitsSetInArray(c) : c=>!f1.bitsClearInArray(c);
            const chk2 = aggr2 ? c=>f2.bitsSetInArray(c) : c=>!f2.bitsClearInArray(c);
            let ok = true;
            if (mode === -1) { // NO
                for (let i=0; i<level.n_tiles; i++) {
                    level.getCellInto(i,_o10);
                    if (chk1(_o10.data)&&chk2(_o10.data)){ok=false;break;}
                }
            } else if (mode === 0) { // SOME
                let any=false;
                for (let i=0; i<level.n_tiles; i++) {
                    level.getCellInto(i,_o10);
                    if (chk1(_o10.data)&&chk2(_o10.data)){any=true;break;}
                }
                if (!any) ok=false;
            } else { // ALL
                for (let i=0; i<level.n_tiles; i++) {
                    level.getCellInto(i,_o10);
                    if (chk1(_o10.data)&&!chk2(_o10.data)){ok=false;break;}
                }
            }
            if (!ok) return false;
        }
        return true;
    }

    // ── BFS state enumeration ─────────────────────────────────────────────────
    function enumerateLevel(levelIndex, objectList, bgId) {
        const ld = state.levels[levelIndex];
        if (!ld || ld.message !== undefined) return null;
        const w = ld.width, h = ld.height;

        const stateMap  = new Map();   // key → index
        const states    = [];          // Uint8Array[]
        const trans     = [];          // {next:[5], win}

        function register(snap) {
            const key = snapKey(snap);
            if (stateMap.has(key)) return stateMap.get(key);
            const idx = states.length;
            stateMap.set(key, idx);
            states.push(snap);
            trans.push({ next:[0xFFFF,0xFFFF,0xFFFF,0xFFFF,0xFFFF], win:0 });
            return idx;
        }

        // Suppress engine side-effects during simulation
        const savedWinning   = winning;
        const savedAgaining  = againing;
        const savedTextMode  = textMode;
        const savedMsgText   = messagetext;
        const savedVerbose   = verbose_logging;
        verbose_logging = false;

        // Load fresh copy of this level
        loadLevelFromState(state, levelIndex, 'sms-bfs');
        const initSnap = snapshot(w, h, objectList, bgId);
        register(initSnap);

        const queue = [0];
        let qi = 0;

        while (qi < queue.length) {
            if (states.length >= MAX_STATES_PER_LEVEL) {
                consolePrint(`[SMS] Level ${levelIndex+1}: hit ${MAX_STATES_PER_LEVEL}-state limit. Truncating.`);
                break;
            }
            const si = queue[qi++];
            const snap = states[si];

            // Restore this state into the live engine
            loadLevelFromState(state, levelIndex, 'sms-bfs');
            applySnap(snap, w, h, objectList, bgId);

            trans[si].win = testWin() ? 1 : 0;

            for (let dir=0; dir<5; dir++) {
                // Save level objects
                const savedObjs = new Int32Array(level.objects);
                const savedMovs = new Int32Array(level.movements);

                winning  = false;
                againing = false;

                // Run the PS rule engine for this input
                processInput(dir, /*dontDoWin=*/true, /*dontModify=*/false);

                winning  = savedWinning;
                againing = savedAgaining;

                const resultSnap = snapshot(w, h, objectList, bgId);
                if (snapKey(resultSnap) === snapKey(snap)) {
                    trans[si].next[dir] = 0xFFFF; // no change
                } else {
                    const rid = register(resultSnap);
                    trans[si].next[dir] = rid;
                    if (!queue.includes(rid)) queue.push(rid);
                }

                // Restore for next input trial
                level.objects   = new Int32Array(savedObjs);
                level.movements = new Int32Array(savedMovs);
                state.calculateRowColMasks(level);
            }
        }

        // Restore global engine state
        winning         = savedWinning;
        againing        = savedAgaining;
        textMode        = savedTextMode;
        messagetext     = savedMsgText;
        verbose_logging = savedVerbose;

        return { width:w, height:h, states, trans };
    }

    // ── Resource filesystem builder ───────────────────────────────────────────
    // Matches what the C ROM expects: single bank 2 block.
    function buildResourceBlock(files) {
        const ENTRY_SIZE = 20;  // name(14)+page(2)+size(2)+offset(2)
        const fileNames  = Object.keys(files).sort();
        const n          = fileNames.length;
        const headerSize = 6;                       // "rsc\0" + u16 count
        const tableSize  = n * ENTRY_SIZE;
        let   dataOffset = headerSize + tableSize;  // where file data starts

        // Flatten to arrays
        const datas = fileNames.map(k => {
            const d = files[k];
            return d instanceof Uint8Array ? d : new Uint8Array(d);
        });

        // Compute total block size
        let total = dataOffset;
        for (const d of datas) total += d.length;

        const block = new Uint8Array(total);
        let p = 0;

        // Header
        block[p++]=0x72; block[p++]=0x73; block[p++]=0x63; block[p++]=0x00; // "rsc\0"
        block[p++]=n&0xFF; block[p++]=(n>>8)&0xFF;                           // u16 count

        // Entry table — we know offsets = dataOffset + running sum
        let fileOff = dataOffset;
        for (let i=0; i<n; i++) {
            const name = fileNames[i];
            for (let c=0; c<14; c++) block[p++] = c<name.length ? name.charCodeAt(c) : 0;
            // page = 2
            block[p++]=2; block[p++]=0;
            // size
            const sz = datas[i].length;
            block[p++]=sz&0xFF; block[p++]=(sz>>8)&0xFF;
            // offset
            block[p++]=fileOff&0xFF; block[p++]=(fileOff>>8)&0xFF;
            fileOff += sz;
        }

        // File data
        for (const d of datas) { block.set(d, p); p += d.length; }

        return block;
    }

    // ── Main export ───────────────────────────────────────────────────────────
    window.exportToPsRom = function () {
        try {
            if (!state || !state.objects || !state.levels || state.levels.length===0) {
                logError('Please compile a game before exporting.', 0);
                return;
            }

            consolePrint('[SMS Export] Starting…');

            // Build object list (all non-background objects with sprites)
            const bgName = 'background';
            const bgId   = state.objects[bgName]?.id ?? -1;
            const objectList = Object.keys(state.objects)
                .filter(n => n!==bgName && state.objects[n].spritematrix && state.objects[n].colors)
                .sort((a,b) => state.objects[a].id - state.objects[b].id);

            if (objectList.length > 60) {
                logError('[SMS] More than 60 objects; truncating to 60.', 0);
                objectList.length = 60;
            }

            // SMS palette + tiles
            const tilePixels = objectList.map(n => upscaleSprite(state.objects[n]));
            const { palette, palRgb } = buildPalette(tilePixels, state.bgcolor);
            const tilData = [
                ...new Array(128).fill(0),                          // tile 0 = blank
                ...tilePixels.flatMap(px => encodeTile16(px, palRgb))
            ];

            // Enumerate states for each playable level
            const gameLevels = state.levels
                .map((ld,i)=>({ld,i}))
                .filter(({ld})=>!ld.message);

            if (gameLevels.length === 0) {
                logError('[SMS] No playable levels found.', 0);
                return;
            }

            const levelResults = [];
            for (const {ld,i} of gameLevels) {
                consolePrint(`[SMS] Level ${i+1} (${ld.width}×${ld.height})…`);
                const r = enumerateLevel(i, objectList, bgId);
                if (r) {
                    consolePrint(`[SMS]   → ${r.states.length} states`);
                    levelResults.push(r);
                }
            }

            if (levelResults.length === 0) {
                logError('[SMS] No levels could be processed.', 0);
                return;
            }

            // Build ps.lvl
            const lvlParts = [new Uint8Array(u16le(levelResults.length))];
            for (const lr of levelResults) {
                lvlParts.push(new Uint8Array([
                    ...u16le(lr.width), ...u16le(lr.height), ...u16le(lr.states.length)
                ]));
                for (const snap of lr.states) lvlParts.push(snap);
            }
            const lvlData = concatUint8(lvlParts);

            // Build ps.trn
            const trnParts = [];
            for (const lr of levelResults) {
                trnParts.push(new Uint8Array(u16le(lr.trans.length)));
                for (const t of lr.trans) {
                    const entry = [];
                    for (let d=0; d<5; d++) entry.push(...u16le(t.next[d]));
                    entry.push(t.win ? 1 : 0);
                    trnParts.push(new Uint8Array(entry));
                }
            }
            const trnData = concatUint8(trnParts);

            // ps.inf
            const projName = (state.metadata?.title) || 'PuzzleScript';
            const infData  = new Uint8Array([...projName].map(c=>c.charCodeAt(0)).concat([0]));

            // Assemble resource block
            const resBlock = buildResourceBlock({
                'ps.inf': infData,
                'ps.lvl': lvlData,
                'ps.pal': new Uint8Array(palette),
                'ps.til': new Uint8Array(tilData),
                'ps.trn': trnData,
            });

            // Fetch base ROM, append resource block, save
            fetch('base-rom/ps_base_rom.sms')
                .then(r => {
                    if (!r.ok) throw new Error('Could not fetch ps_base_rom.sms: '+r.status);
                    return r.arrayBuffer();
                })
                .then(romBuf => {
                    const romBytes = new Uint8Array(romBuf);
                    const final    = concatUint8([romBytes, resBlock]);
                    const safeName = projName.replace(/[^A-Za-z0-9]/g,'_').replace(/_+/g,'_');
                    saveAs(final, 'application/octet-stream', safeName + '_ps.sms');
                    consolePrint(`[SMS Export] Done — ${final.length} bytes → ${safeName}_ps.sms`);
                })
                .catch(err => { logError('SMS export failed: '+err.message, 0); });

        } catch(err) {
            logError('SMS export error: '+err.message, 0);
            console.error('[SMS Export]', err);
        }
    };

    function concatUint8(arrays) {
        const total = arrays.reduce((s,a)=>s+a.length, 0);
        const out   = new Uint8Array(total);
        let off = 0;
        for (const a of arrays) { out.set(a, off); off += a.length; }
        return out;
    }

})();
