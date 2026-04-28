'use strict';

/**
 * PuzzleScript → Sega Master System ROM Exporter
 *
 * Pipeline:
 *  1. Read compiled `state` (objects, levels, collision layers)
 *  2. Upscale each 5×5 PuzzleScript sprite to 16×16 (nearest-neighbour)
 *  3. Collect unique colours across all sprites; quantise to SMS 6-bit palette
 *  4. Convert each 16×16 tile to SMS 4-plane bitformat
 *  5. Build level maps (width × height arrays of tile indices)
 *  6. Pack everything into the resource filesystem used by SMS-Puzzle-Maker
 *  7. Append to the base ROM and trigger a download
 */

(function () {

    // ── SMS palette helpers ────────────────────────────────────────────────

    /** Round an 8-bit channel value to the nearest SMS 2-bit level (0/85/170/255) */
    function toSms2bit(ch) {
        // SMS has 4 levels per channel: 0,1,2,3 (encoded as 2 bits)
        // In 8-bit space those map to 0, 85, 170, 255
        return Math.round(ch / 85);   // 0-3
    }

    /** Convert a CSS hex colour string → { r, g, b } 0-255 */
    function hexToRgb(hex) {
        hex = hex.replace(/^#/, '');
        if (hex.length === 3) hex = hex.split('').map(c => c + c).join('');
        return {
            r: parseInt(hex.slice(0, 2), 16),
            g: parseInt(hex.slice(2, 4), 16),
            b: parseInt(hex.slice(4, 6), 16)
        };
    }

    /** Quantise { r,g,b } to nearest SMS colour; return SMS byte (BBGGRR 2-bit each) */
    function rgbToSmsByte(r, g, b) {
        const sr = toSms2bit(r);
        const sg = toSms2bit(g);
        const sb = toSms2bit(b);
        return sr | (sg << 2) | (sb << 4);
    }

    /** Quantise { r,g,b } → { r,g,b } snapped to the nearest SMS colour (8-bit space) */
    function quantiseRgb(r, g, b) {
        return {
            r: toSms2bit(r) * 85,
            g: toSms2bit(g) * 85,
            b: toSms2bit(b) * 85
        };
    }

    /** Colour distance (squared) in RGB space */
    function colDist2(r1, g1, b1, r2, g2, b2) {
        return (r1 - r2) ** 2 + (g1 - g2) ** 2 + (b1 - b2) ** 2;
    }

    // ── Sprite upscaling ──────────────────────────────────────────────────

    const SRC_SIZE = 5;   // PuzzleScript sprite grid is always 5×5
    const TILE_SIZE = 16; // target SMS tile size

    /**
     * Convert a PuzzleScript object definition into a 16×16 pixel array.
     * Each element is an RGBA array [r, g, b, a].
     *
     * @param {Object} obj  - state.objects[name]: { colors, spritematrix }
     * @returns {Array}     - 16×16 array of [r,g,b,a]
     */
    function upscaleSprite(obj) {
        const colors = obj.colors;          // array of CSS colour strings (up to 10)
        const matrix = obj.spritematrix;    // 5×5 array of colour indices (-1 = transparent)

        // Resolve CSS colours to RGB
        const resolvedColors = colors.map(c => {
            if (!c || c === 'transparent') return null;
            try { return hexToRgb(c.trim()); } catch (e) { return null; }
        });

        // Build 16×16 pixel grid via nearest-neighbour upscale
        const pixels = [];
        for (let ty = 0; ty < TILE_SIZE; ty++) {
            const srcY = Math.floor(ty * SRC_SIZE / TILE_SIZE);
            const row = [];
            for (let tx = 0; tx < TILE_SIZE; tx++) {
                const srcX = Math.floor(tx * SRC_SIZE / TILE_SIZE);
                const colorIdx = (matrix[srcY] !== undefined) ? matrix[srcY][srcX] : -1;
                if (colorIdx < 0 || colorIdx >= resolvedColors.length || !resolvedColors[colorIdx]) {
                    row.push(null); // transparent
                } else {
                    const c = resolvedColors[colorIdx];
                    row.push([c.r, c.g, c.b, 255]);
                }
            }
            pixels.push(row);
        }
        return pixels;
    }

    // ── Palette building ──────────────────────────────────────────────────

    /**
     * Given an array of tile pixel grids, build an SMS palette of up to 15 colours
     * (index 0 is reserved as transparent/background).
     *
     * Returns:
     *   palette   – array of up to 16 SMS colour bytes (index 0 = 0x00 transparent)
     *   smsPalRgb – same palette but as { r, g, b } in quantised 8-bit space
     */
    function buildPalette(tilePixels, bgColor) {
        // Collect all unique quantised colours
        const colorSet = new Map(); // key = "r,g,b" → SMS byte

        // Always include background as index 0
        let bgRgb = { r: 0, g: 0, b: 0 };
        if (bgColor) {
            try { bgRgb = quantiseRgb(...Object.values(hexToRgb(bgColor))); } catch (e) {}
        }
        const bgKey = `${bgRgb.r},${bgRgb.g},${bgRgb.b}`;
        colorSet.set(bgKey, { sms: rgbToSmsByte(bgRgb.r, bgRgb.g, bgRgb.b), rgb: bgRgb });

        for (const pixels of tilePixels) {
            for (const row of pixels) {
                for (const px of row) {
                    if (!px) continue;
                    const q = quantiseRgb(px[0], px[1], px[2]);
                    const key = `${q.r},${q.g},${q.b}`;
                    if (!colorSet.has(key)) {
                        colorSet.set(key, { sms: rgbToSmsByte(q.r, q.g, q.b), rgb: q });
                    }
                }
            }
        }

        // Limit to 16 colours (SMS hardware limit for background tiles)
        const entries = [...colorSet.values()].slice(0, 16);
        const palette = entries.map(e => e.sms);
        const smsPalRgb = entries.map(e => e.rgb);

        // Pad to 16
        while (palette.length < 16) palette.push(0);
        while (smsPalRgb.length < 16) smsPalRgb.push({ r: 0, g: 0, b: 0 });

        return { palette, smsPalRgb };
    }

    // ── Tile encoding ─────────────────────────────────────────────────────

    /**
     * Find the closest palette index for a given RGB colour.
     */
    function nearestPaletteIndex(r, g, b, smsPalRgb) {
        let best = 0;
        let bestDist = Infinity;
        for (let i = 0; i < smsPalRgb.length; i++) {
            const p = smsPalRgb[i];
            const d = colDist2(r, g, b, p.r, p.g, p.b);
            if (d < bestDist) { bestDist = d; best = i; }
        }
        return best;
    }

    /**
     * Convert a 16×16 pixel grid to SMS 4-bitplane tile data.
     * Returns a flat array of 4*16 = 64 bytes per tile.
     *
     * SMS tile format: for each of 16 rows, 4 bytes (one per bitplane).
     * Each byte encodes 8 pixels (MSB = leftmost pixel).
     *
     * Wait — SMS tiles are 8×8! A 16×16 PuzzleScript tile maps to a 2×2 block
     * of four 8×8 SMS tiles. We return all four tiles concatenated.
     */
    function encodeTile16(pixels, smsPalRgb) {
        // pixels is 16×16. Split into four 8×8 quadrants: TL, TR, BL, BR
        const quadrants = [
            { ox: 0, oy: 0 },
            { ox: 8, oy: 0 },
            { ox: 0, oy: 8 },
            { ox: 8, oy: 8 }
        ];

        const result = [];
        for (const { ox, oy } of quadrants) {
            for (let row = 0; row < 8; row++) {
                const planes = [0, 0, 0, 0];
                for (let col = 0; col < 8; col++) {
                    const px = pixels[oy + row][ox + col];
                    let palIdx;
                    if (!px) {
                        palIdx = 0; // transparent → background colour
                    } else {
                        const q = quantiseRgb(px[0], px[1], px[2]);
                        palIdx = nearestPaletteIndex(q.r, q.g, q.b, smsPalRgb);
                    }
                    const bitMask = 0x80 >> col;
                    for (let p = 0; p < 4; p++) {
                        if (palIdx & (1 << p)) planes[p] |= bitMask;
                    }
                }
                result.push(...planes);
            }
        }
        return result; // 4 tiles × 8 rows × 4 bytes = 128 bytes
    }

    // ── Level map building ────────────────────────────────────────────────

    /**
     * Convert a compiled PuzzleScript level into a flat SMS tile-index map.
     *
     * PuzzleScript levels store cells as BitVec arrays.  Each cell has one
     * object per collision layer; we pick the topmost non-background object.
     *
     * Returns { width, height, tileIndexes } where tileIndexes is a 2-D array
     * (row-major) of 1-based SMS tile indices (0 = empty/background).
     */
    function buildLevelMap(levelDat, state, objectIdToTileIndex) {
        if (!levelDat || levelDat.message !== undefined) return null;

        const w = levelDat.width;
        const h = levelDat.height;
        const bgId = state.objects['background'] ? state.objects['background'].id : -1;

        const tileIndexes = [];
        for (let row = 0; row < h; row++) {
            const rowArr = [];
            for (let col = 0; col < w; col++) {
                const cellIndex = col * h + row; // PuzzleScript column-major storage
                // Walk layers from top to bottom; pick first non-background object
                let chosen = 0;
                for (let layer = state.LAYER_COUNT - 1; layer >= 0; layer--) {
                    // Read the object id from the Int32Array backing the level
                    // Each cell uses STRIDE_OBJ words; bit `id` indicates presence
                    const wordOffset = cellIndex * state.STRIDE_OBJ;
                    for (let objName of Object.keys(state.objects)) {
                        const obj = state.objects[objName];
                        if (obj.layer !== layer) continue;
                        if (obj.id === bgId) continue;
                        const word = levelDat.objects[wordOffset + Math.floor(obj.id / 32)];
                        const bit = 1 << (obj.id % 32);
                        if (word & bit) {
                            const tileIdx = objectIdToTileIndex[obj.id];
                            if (tileIdx !== undefined) {
                                chosen = tileIdx + 1; // 1-based
                            }
                            break;
                        }
                    }
                    if (chosen) break;
                }
                rowArr.push(chosen);
            }
            tileIndexes.push(rowArr);
        }
        return { width: w, height: h, tileIndexes };
    }

    // ── Resource filesystem (from SMS-Puzzle-Maker) ───────────────────────

    function padArrayEnd(arr, len, padding) {
        return arr.concat(Array(Math.max(0, len - arr.length)).fill(padding));
    }
    const stringToPaddedByteArray = (s, len) =>
        padArrayEnd([...s].map(ch => ch.charCodeAt(0)), len, 0);
    const toBytePair = n => [n & 0xFF, (n >> 8) & 0xFF];
    const flatten = arr => arr.reduce((a, b) => a.concat(Array.isArray(b) ? flatten(b) : b), []);

    function buildInternalFiles(palette, tileset, maps, projectName) {
        // tileset: flat array of SMS tile bytes (all tiles concatenated)
        // maps: array of { name, width, height, tileIndexes }
        const mapFiles = {};
        maps.forEach(({ name, width, height, tileIndexes }, idx) => {
            const fileName = `level${String(idx + 1).padStart(3, '0')}.map`;
            const flatTiles = flatten(tileIndexes);
            mapFiles[fileName] = [
                ...toBytePair(idx + 1),
                ...toBytePair(width),
                ...toBytePair(height),
                ...stringToPaddedByteArray(name || `Level ${idx + 1}`, 32),
                ...flatTiles
            ];
        });

        return {
            'main.pal': padArrayEnd([...palette], 16, 0),
            'main.til': tileset,
            'project.inf': [...('PuzzleScript-SMS\0').split('').map(c => c.charCodeAt(0)),
                            ...((projectName || 'Game') + '\0').split('').map(c => c.charCodeAt(0))],
            ...mapFiles
        };
    }

    function buildFileSystem(internalFiles) {
        const PAGE_SIZE = 16 * 1024;
        const INITIAL_PAGE = 2;
        const fileEntryFormat = { name: 14, page: 2, size: 2, offset: 2 };
        const fileEntrySize = Object.values(fileEntryFormat).reduce((a, b) => a + b, 0);

        const fileEntries = Object.keys(internalFiles).sort()
            .map(fileName => ({ fileName, content: internalFiles[fileName] }));
        const fileEntriesSize = fileEntries.length * fileEntrySize;

        const header = [...stringToPaddedByteArray('rsc', 4), ...toBytePair(fileEntries.length)];
        const fileContentInitialOffset = header.length + fileEntriesSize;

        let nextPageNumber = INITIAL_PAGE;
        let fileContentOffset = fileContentInitialOffset;

        const allocated = fileEntries.map(({ fileName, content }) => {
            if (fileContentOffset + content.length > PAGE_SIZE) {
                nextPageNumber++;
                fileContentOffset = 0;
            }
            const entry = { fileName, pageNumber: nextPageNumber, offset: fileContentOffset, content };
            fileContentOffset += content.length;
            return entry;
        });

        const entriesTable = flatten(allocated.map(({ fileName, pageNumber, offset, content }) => [
            ...stringToPaddedByteArray(fileName, fileEntryFormat.name),
            ...toBytePair(pageNumber),
            ...toBytePair(content.length),
            ...toBytePair(offset)
        ]));

        const pages = [[...header, ...entriesTable]];
        allocated.forEach(({ pageNumber, offset, content }) => {
            const pi = pageNumber - INITIAL_PAGE;
            if (!pages[pi]) pages[pi] = new Array(PAGE_SIZE).fill(0);
            const p = pages[pi];
            while (p.length < PAGE_SIZE) p.push(0);
            content.forEach((byte, i) => { p[offset + i] = byte; });
        });

        return flatten(pages);
    }

    // ── Public entry point ────────────────────────────────────────────────

    /**
     * Called from the toolbar.  Reads the global `state` produced by compile(),
     * builds the ROM resource, fetches the base ROM, and saves the result.
     */
    window.exportToSmsRom = function () {
        try {
            if (!state || !state.objects) {
                logError('Please compile the game before exporting to SMS ROM.', 0);
                return;
            }

            // ── 1. Gather all object sprites (skip background for tiles,
            //       but include it as colour 0 in the palette) ──────────────
            const objNames = Object.keys(state.objects);
            const bgColor = state.bgcolor || '#000000';

            // Build sprite pixel grids for every object
            const objectList = objNames.map(name => ({
                name,
                obj: state.objects[name]
            })).filter(({ obj }) => obj.spritematrix && obj.colors);

            // Sort by id so tile indices are stable
            objectList.sort((a, b) => a.obj.id - b.obj.id);

            const tilePixels = objectList.map(({ obj }) => upscaleSprite(obj));

            // ── 2. Build SMS palette ───────────────────────────────────────
            const { palette, smsPalRgb } = buildPalette(tilePixels, bgColor);

            // ── 3. Encode tiles ────────────────────────────────────────────
            // Each 16×16 tile encodes to 4 SMS 8×8 tiles (128 bytes)
            const allTileBytes = [];
            const objectIdToTileIndex = {}; // PuzzleScript object id → index in our tile array
            // Tile index 0 is reserved (background / empty).  We use a blank tile for it.
            const blankTile = new Array(128).fill(0);
            allTileBytes.push(...blankTile); // tile 0

            objectList.forEach(({ obj }, i) => {
                objectIdToTileIndex[obj.id] = i + 1; // 1-based (0 = blank)
                allTileBytes.push(...encodeTile16(tilePixels[i], smsPalRgb));
            });

            // ── 4. Build level maps ────────────────────────────────────────
            const smsLevels = [];
            if (state.levels) {
                state.levels.forEach((levelDat, idx) => {
                    if (levelDat.message !== undefined) return; // skip message screens
                    const map = buildLevelMap(levelDat, state, objectIdToTileIndex);
                    if (map) {
                        smsLevels.push({ name: `Level ${idx + 1}`, ...map });
                    }
                });
            }

            if (smsLevels.length === 0) {
                // Fallback: create a minimal blank level so the ROM is valid
                smsLevels.push({ name: 'Level 1', width: 16, height: 9,
                    tileIndexes: Array.from({ length: 9 }, () => new Array(16).fill(0)) });
            }

            // ── 5. Build resource filesystem ───────────────────────────────
            const projectName = (state.metadata && state.metadata.title) || 'PuzzleScript_SMS';
            const internalFiles = buildInternalFiles(palette, allTileBytes, smsLevels, projectName);
            const resourceData = buildFileSystem(internalFiles);
            const resourceBlob = new Blob([new Uint8Array(resourceData)],
                { type: 'application/octet-stream' });

            // ── 6. Fetch base ROM and concatenate ──────────────────────────
            fetch('base-rom/puzzle_maker_base_rom.sms', { method: 'GET' })
                .then(r => {
                    if (!r.ok) throw new Error('Could not load base ROM (HTTP ' + r.status + ')');
                    return r.blob();
                })
                .then(baseRomBlob => {
                    const finalBlob = new Blob([baseRomBlob, resourceBlob],
                        { type: 'application/octet-stream' });
                    const safeName = projectName.replace(/[^A-Za-z0-9]/g, '_').replace(/_+/g, '_');
                    saveAs(finalBlob, 'application/octet-stream', safeName + '.sms');
                    console.log('[SMS Export] ROM generated successfully.');
                    console.log(`  Objects: ${objectList.length}  Levels: ${smsLevels.length}  Palette: ${palette.length} colours`);
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
