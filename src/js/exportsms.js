/* ============================================================================
   exportsms.js — Export the compiled PuzzleScript game as a Sega Master
   System ROM (.sms).

   Consumes the *compiled* engine state (bitmask cell patterns, exactly what
   engine.js executes) and serialises it into the data format understood by
   sms/base-rom/ps_engine.c, then appends it to the prebuilt 32 KB base ROM
   (banks 0-1 = Z80 engine, banks 2+ = game data, standard Sega mapper).

   Every PuzzleScript object (5x5 sprite) is scaled to a 16x16 tile
   (nearest-neighbour) and stored as 4 SMS subtiles of 8 rows x
   (1 transparency-mask byte + 4 planar bytes) = 160 bytes per object,
   so the Z80 can composite stacked objects with per-pixel transparency.

   Engine subset (exporter fails or warns when the game goes beyond it):
     - up to 32 objects, 6 collision layers, 255 levels of max 16x12 cells
     - no ellipsis [ a | ... | b ], no rigid bodies, no realtime, no
       startloop/endloop, no flickscreen/zoomscreen, no sounds
     - random rules are applied deterministically-ish (warned)
   ========================================================================= */

'use strict';

(function (global) {

var SMS_BANK_SIZE = 16384;
var SMS_DATA_BANK = 2;
var SMS_MAX_W = 16, SMS_MAX_H = 12;
var HEADER_SIZE = 203;

/* ------------------------------------------------------------ helpers --- */

function smsQuantChannel(v) { return v < 43 ? 0 : v < 128 ? 1 : v < 213 ? 2 : 3; }

function hexToRGB(hex) {
    hex = (hex || '#000000').replace('#', '');
    if (hex.length === 3) hex = hex[0]+hex[0]+hex[1]+hex[1]+hex[2]+hex[2];
    return [parseInt(hex.slice(0,2),16)||0, parseInt(hex.slice(2,4),16)||0, parseInt(hex.slice(4,6),16)||0];
}

function hexToSMS(hex) {
    var c = hexToRGB(hex);
    return smsQuantChannel(c[0]) | (smsQuantChannel(c[1]) << 2) | (smsQuantChannel(c[2]) << 4);
}

function u32bytes(v) {
    v = v >>> 0;
    return [v & 0xFF, (v >>> 8) & 0xFF, (v >>> 16) & 0xFF, (v >>> 24) & 0xFF];
}

function bv32(bitvec) {
    /* BitVec (STRIDE 1) -> unsigned 32-bit int */
    if (!bitvec) return 0;
    if (typeof bitvec === 'number') return bitvec >>> 0;
    return (bitvec.data[0] || 0) >>> 0;
}

function asciiBytes(s, maxlen) {
    var out = [];
    for (var i = 0; i < s.length && (maxlen === undefined || out.length < maxlen); i++) {
        var c = s.charCodeAt(i);
        if (c === 10) { out.push(10); continue; }
        if (c < 32 || c > 126) c = 63; /* '?' */
        out.push(c);
    }
    return out;
}

function SMSExportError(msg) { this.message = msg; }

/* ----------------------------------------------------------- palette ---- */

function buildPalette(state, warnings) {
    /* index 0 = background colour, index 15 = text colour,
       object colours fill 1..14 (then reuse 0/15 on exact match,
       then nearest-match). */
    var pal = new Array(16).fill(null);
    pal[0]  = hexToSMS(state.bgcolor || '#000000');
    pal[15] = hexToSMS(state.fgcolor || '#FFFFFF');

    var used = 1; /* next free in 1..14 */
    var mapColor = function (hex) {
        var b = hexToSMS(hex);
        for (var i = 0; i < 16; i++) if (pal[i] === b) return i;
        if (used <= 14) { pal[used] = b; return used++; }
        /* nearest match on 2-bit channels */
        var rgb = [b & 3, (b >> 2) & 3, (b >> 4) & 3];
        var best = 0, bestd = 1e9;
        for (var j = 0; j < 16; j++) {
            if (pal[j] === null) continue;
            var q = [pal[j] & 3, (pal[j] >> 2) & 3, (pal[j] >> 4) & 3];
            var d = Math.pow(rgb[0]-q[0],2) + Math.pow(rgb[1]-q[1],2) + Math.pow(rgb[2]-q[2],2);
            if (d < bestd) { bestd = d; best = j; }
        }
        if (bestd > 0) warnings.push('Palette full (SMS has 16 colours): "' + hex + '" mapped to nearest.');
        return best;
    };

    var objPalIdx = {}; /* objectName -> [global idx per local colour] */
    for (var i = 0; i < state.objectCount; i++) {
        var name = state.idDict[i];
        var o = state.objects[name];
        objPalIdx[name] = o.colors.map(mapColor);
    }
    for (var k = 0; k < 16; k++) if (pal[k] === null) pal[k] = 0;
    return { bytes: pal, objPalIdx: objPalIdx };
}

/* ------------------------------------------------ sprites -> 16x16 ------ */

function scaleSpriteTo16(spritematrix, localToGlobal) {
    /* 5x5 (values: -1 transparent or colour index) -> 16x16 global indices,
       -1 = transparent, nearest neighbour */
    var g = [];
    for (var y = 0; y < 16; y++) {
        var row = [];
        var sy = Math.floor(y * 5 / 16);
        for (var x = 0; x < 16; x++) {
            var sx = Math.floor(x * 5 / 16);
            var v = (spritematrix[sy] !== undefined && spritematrix[sy][sx] !== undefined)
                    ? spritematrix[sy][sx] : -1;
            row.push(v < 0 ? -1 : (localToGlobal[v] !== undefined ? localToGlobal[v] : 0));
        }
        g.push(row);
    }
    return g;
}

function encodeObjectGfx(grid16) {
    /* -> 160 bytes: subtiles TL,TR,BL,BR; per row: mask, plane0..3 */
    var out = [];
    var quads = [[0,0],[0,8],[8,0],[8,8]]; /* [row0, col0] TL TR BL BR */
    for (var q = 0; q < 4; q++) {
        var r0 = quads[q][0], c0 = quads[q][1];
        for (var r = 0; r < 8; r++) {
            var mask = 0, planes = [0,0,0,0];
            for (var c = 0; c < 8; c++) {
                var v = grid16[r0 + r][c0 + c];
                if (v < 0) continue;
                var bit = 0x80 >> c;
                mask |= bit;
                for (var p = 0; p < 4; p++) if (v & (1 << p)) planes[p] |= bit;
            }
            out.push(mask, planes[0], planes[1], planes[2], planes[3]);
        }
    }
    return out;
}

/* --------------------------------------------------------------- rules -- */

var CMD_BITS = { cancel:1, restart:2, win:4, again:8, checkpoint:16, message:32 };

function serializeCell(cell, warnings) {
    var out = [];
    var rep = cell.replacement;
    var anyMasks = (cell.anyObjectsPresent || []).map(bv32);
    var flags = 0;
    var randE = 0, randD = 0;
    if (rep) {
        flags |= 1;
        randE = bv32(rep.randomEntityMask);
        randD = bv32(rep.randomDirMask);
        if (randE) flags |= 2;
        if (randD) flags |= 4;
    }
    out.push(flags, anyMasks.length);
    out.push.apply(out, u32bytes(bv32(cell.objectsPresent)));
    out.push.apply(out, u32bytes(bv32(cell.objectsMissing)));
    out.push.apply(out, u32bytes(bv32(cell.movementsPresent)));
    out.push.apply(out, u32bytes(bv32(cell.movementsMissing)));
    for (var a = 0; a < anyMasks.length; a++) out.push.apply(out, u32bytes(anyMasks[a]));
    if (rep) {
        out.push.apply(out, u32bytes(bv32(rep.objectsClear)));
        out.push.apply(out, u32bytes(bv32(rep.objectsSet)));
        /* engine.js: movements cleared = movementsClear | movementsLayerMask */
        out.push.apply(out, u32bytes((bv32(rep.movementsClear) | bv32(rep.movementsLayerMask)) >>> 0));
        out.push.apply(out, u32bytes(bv32(rep.movementsSet)));
        if (flags & 2) out.push.apply(out, u32bytes(randE));
        if (flags & 4) out.push.apply(out, u32bytes(randD));
    }
    return out;
}

function serializeRuleGroups(groups, packer, warnings, label) {
    var out = [groups.length & 0xFF];
    if (groups.length > 255) throw new SMSExportError('Too many ' + label + ' rule groups (max 255).');
    for (var g = 0; g < groups.length; g++) {
        var group = groups[g];
        if (group.length > 255) throw new SMSExportError('Rule group too large.');
        out.push(group.length);
        for (var r = 0; r < group.length; r++) {
            var rule = group[r];
            if (rule.ellipsisCount && rule.ellipsisCount.some(function (c) { return c > 0; }))
                throw new SMSExportError('Ellipsis rules ("...") are not supported by the SMS export (rule at line ' + rule.lineNumber + ').');
            if (rule.rigid)
                warnings.push('Rigid rule at line ' + rule.lineNumber + ' exported as non-rigid.');
            if (rule.isRandom)
                warnings.push('Random rule at line ' + rule.lineNumber + ': SMS export applies it like a normal rule.');
            if (rule.patterns.length > 6)
                throw new SMSExportError('Rule at line ' + rule.lineNumber + ' has more than 6 cell rows.');

            var dir = rule.direction;
            if (dir !== 1 && dir !== 2 && dir !== 4 && dir !== 8) dir = 8;

            var cmdBits = 0, msgFar = [0xFF, 0, 0];
            for (var c = 0; c < (rule.commands || []).length; c++) {
                var cmd = rule.commands[c][0];
                if (CMD_BITS[cmd] !== undefined) {
                    cmdBits |= CMD_BITS[cmd];
                    if (cmd === 'message') {
                        var txt = rule.commands[c][1] || '';
                        msgFar = packer.addBlob(asciiBytes(txt).concat([0]));
                    }
                } else if (cmd.indexOf('sfx') !== 0) {
                    warnings.push('Command "' + cmd + '" (line ' + rule.lineNumber + ') not supported; ignored.');
                }
            }

            out.push(dir, rule.isRandom ? 1 : 0, cmdBits);
            out.push(msgFar[0], msgFar[1], msgFar[2]);
            out.push(rule.patterns.length);
            for (var row = 0; row < rule.patterns.length; row++) {
                var cells = rule.patterns[row];
                if (cells.length > 255) throw new SMSExportError('Cell row too long.');
                out.push(cells.length);
                for (var cc = 0; cc < cells.length; cc++)
                    out.push.apply(out, serializeCell(cells[cc], warnings));
            }
        }
    }
    return out;
}

/* -------------------------------------------------------- bank packer --- */

function BankPacker() {
    this.banks = [new Uint8Array(SMS_BANK_SIZE)];
    this.cursor = HEADER_SIZE;   /* bank 2 starts with the header */
}
BankPacker.prototype.addBlob = function (bytes) {
    if (bytes.length > SMS_BANK_SIZE)
        throw new SMSExportError('A single data blob (' + bytes.length + ' bytes) exceeds one 16 KB bank. Simplify the game.');
    if (this.cursor + bytes.length > SMS_BANK_SIZE) {
        this.banks.push(new Uint8Array(SMS_BANK_SIZE));
        this.cursor = 0;
    }
    var bankIdx = this.banks.length - 1;
    var off = this.cursor;
    this.banks[bankIdx].set(bytes, off);
    this.cursor += bytes.length;
    return [SMS_DATA_BANK + bankIdx, off & 0xFF, (off >> 8) & 0xFF]; /* farptr */
};
BankPacker.prototype.writeHeader = function (bytes) {
    if (bytes.length > HEADER_SIZE) throw new SMSExportError('internal: header too big');
    this.banks[0].set(bytes, 0);
};
BankPacker.prototype.dataBytes = function () {
    var out = new Uint8Array(this.banks.length * SMS_BANK_SIZE);
    for (var i = 0; i < this.banks.length; i++) out.set(this.banks[i], i * SMS_BANK_SIZE);
    return out;
};

/* ------------------------------------------------------------- main ----- */

function buildSMSData(state, warnings) {
    /* ---- validation ---- */
    if (!state || !state.levels || state.levels.length === 0)
        throw new SMSExportError('No compiled game. Run the game first.');
    if (state.objectCount > 32)
        throw new SMSExportError('SMS export supports up to 32 objects; this game has ' + state.objectCount + '.');
    if (state.collisionLayers.length > 6)
        throw new SMSExportError('SMS export supports up to 6 collision layers; this game has ' + state.collisionLayers.length + '.');
    if (state.levels.length > 255)
        throw new SMSExportError('SMS export supports up to 255 levels.');
    if ('realtime_interval' in state.metadata)
        throw new SMSExportError('realtime_interval games are not supported by the SMS export.');
    if ('flickscreen' in state.metadata || 'zoomscreen' in state.metadata)
        warnings.push('flickscreen/zoomscreen are ignored by the SMS export.');
    if (state.loopPoint && Object.keys(state.loopPoint).length > 0)
        warnings.push('startloop/endloop is not supported; rule groups run sequentially.');

    for (var li = 0; li < state.levels.length; li++) {
        var lv = state.levels[li];
        if (lv.message !== undefined) continue;
        if (lv.width > SMS_MAX_W || lv.height > SMS_MAX_H)
            throw new SMSExportError('Level ' + (li + 1) + ' is ' + lv.width + 'x' + lv.height +
                '; the SMS export supports at most ' + SMS_MAX_W + 'x' + SMS_MAX_H + ' (16x16px cells on a 256x192 screen).');
    }

    var packer = new BankPacker();

    /* ---- palette & object graphics ---- */
    var palInfo = buildPalette(state, warnings);
    var gfxBytes = [];
    for (var oi = 0; oi < state.objectCount; oi++) {
        var name = state.idDict[oi];
        var o = state.objects[name];
        var grid = scaleSpriteTo16(o.spritematrix, palInfo.objPalIdx[name]);
        gfxBytes.push.apply(gfxBytes, encodeObjectGfx(grid));
    }
    var gfxFar = packer.addBlob(gfxBytes);

    /* ---- rules ---- */
    var rulesFar = packer.addBlob(serializeRuleGroups(state.rules || [], packer, warnings, 'early'));
    var lateFar  = packer.addBlob(serializeRuleGroups(state.lateRules || [], packer, warnings, 'late'));

    /* ---- win conditions ---- */
    var wcBytes = [state.winconditions.length];
    for (var w = 0; w < state.winconditions.length; w++) {
        var wc = state.winconditions[w];
        /* [num(-1 no,0 some,1 all), mask1, mask2, line, aggr1, aggr2] */
        var type = wc[0] === -1 ? 0 : wc[0] === 0 ? 1 : 2;
        var aggr = (wc[4] ? 1 : 0) | (wc[5] ? 2 : 0);
        wcBytes.push(type, aggr);
        wcBytes.push.apply(wcBytes, u32bytes(bv32(wc[1])));
        wcBytes.push.apply(wcBytes, u32bytes(bv32(wc[2])));
    }
    var winFar = packer.addBlob(wcBytes);

    /* ---- levels ---- */
    var levelFars = [];
    for (var l = 0; l < state.levels.length; l++) {
        var lev = state.levels[l];
        if (lev.message !== undefined) {
            levelFars.push(packer.addBlob([1].concat(asciiBytes(String(lev.message)), [0])));
        } else {
            var bytes = [0, lev.width, lev.height];
            for (var ci = 0; ci < lev.width * lev.height; ci++)
                bytes.push.apply(bytes, u32bytes(lev.objects[ci] >>> 0));
            levelFars.push(packer.addBlob(bytes));
        }
    }
    var idxBytes = [];
    for (var f = 0; f < levelFars.length; f++) idxBytes.push.apply(idxBytes, levelFars[f]);
    var levelsFar = packer.addBlob(idxBytes);

    /* ---- header ---- */
    var flags = 0;
    if ('run_rules_on_level_start' in state.metadata) flags |= 1;
    if ('noaction' in state.metadata) flags |= 2;
    if ('noundo' in state.metadata) flags |= 4;
    if ('norestart' in state.metadata) flags |= 8;
    var againFrames = 8;
    if ('again_interval' in state.metadata) {
        var s = parseFloat(state.metadata.again_interval);
        if (!isNaN(s)) againFrames = Math.max(1, Math.min(255, Math.round(s * 60)));
    }

    var hdr = new Uint8Array(HEADER_SIZE);
    hdr.set([0x50, 0x53, 0x4D, 0x53, 1], 0);              /* "PSMS", version */
    hdr[5] = state.objectCount;
    hdr[6] = state.collisionLayers.length;
    hdr[7] = state.levels.length;
    hdr[8] = flags;
    hdr[9] = againFrames;
    var pm = state.playerMask;
    if (Object.prototype.toString.call(pm) === '[object Array]') pm = pm[1];
    hdr.set(u32bytes(bv32(pm)), 12);
    for (var ly = 0; ly < 6; ly++)
        hdr.set(u32bytes(ly < state.layerMasks.length ? bv32(state.layerMasks[ly]) : 0), 16 + ly * 4);
    for (var ob = 0; ob < 32; ob++)
        hdr[40 + ob] = ob < state.objectCount ? state.objects[state.idDict[ob]].layer : 0;
    /* draw order: objects sorted by (layer, id), bottom first */
    var order = [];
    for (var d = 0; d < state.objectCount; d++) order.push(d);
    order.sort(function (a, b) {
        var la = state.objects[state.idDict[a]].layer, lb = state.objects[state.idDict[b]].layer;
        return la !== lb ? la - lb : a - b;
    });
    for (var d2 = 0; d2 < 32; d2++) hdr[72 + d2] = d2 < order.length ? order[d2] : 0xFF;
    hdr.set(palInfo.bytes, 104);
    hdr.set(gfxFar, 120);
    hdr.set(rulesFar, 123);
    hdr.set(lateFar, 126);
    hdr.set(winFar, 129);
    hdr.set(levelsFar, 132);
    var title = (state.metadata.title || 'PUZZLESCRIPT GAME');
    var author = (state.metadata.author || '');
    hdr.set(asciiBytes(title, 33), 135);
    hdr.set(asciiBytes(author, 33), 169);
    packer.writeHeader(hdr);

    return packer.dataBytes();
}

function b64ToBytes(b64) {
    var bin, out, i;
    if (typeof atob === 'function') {
        bin = atob(b64);
        out = new Uint8Array(bin.length);
        for (i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
        return out;
    }
    return new Uint8Array(Buffer.from(b64, 'base64'));
}

function buildSMSRomFromState(state, baseRomBytes, warnings) {
    warnings = warnings || [];
    var data = buildSMSData(state, warnings);
    if (baseRomBytes.length !== 32768)
        throw new SMSExportError('internal: base ROM must be exactly 32 KB (got ' + baseRomBytes.length + ').');
    var rom = new Uint8Array(baseRomBytes.length + data.length);
    rom.set(baseRomBytes, 0);
    rom.set(data, baseRomBytes.length);
    return rom;
}

/* ------------------------------------------------------ editor entry ---- */

function exportSMSClick() {
    try {
        compile(['restart']);
    } catch (e) { /* compile logs its own errors */ }

    try {
        if (typeof PS_SMS_BASE_ROM_B64 === 'undefined' || PS_SMS_BASE_ROM_B64.indexOf('PLACEHOLDER') === 0)
            throw new SMSExportError('Base ROM missing: run sms/tools/embed_base_rom.py (see sms/README.md).');

        var warnings = [];
        var rom = buildSMSRomFromState(state, b64ToBytes(PS_SMS_BASE_ROM_B64), warnings);

        for (var i = 0; i < warnings.length; i++)
            consolePrint('SMS export warning: ' + warnings[i]);

        var fname = ((state.metadata.title || 'puzzlescript-game')
                        .replace(/[^A-Za-z0-9 _-]/g, '').trim().replace(/ +/g, '_') || 'game') + '.sms';
        /* Note: don't use PuzzleScript's global saveAs() here — its signature
           is saveAs(text, type, filename), not the FileSaver saveAs(blob,name),
           so passing (blob, fname) drops the filename and the browser saves a
           default *.txt. Trigger the download explicitly instead. */
        var blob = new Blob([rom], { type: 'application/octet-stream' });
        var a = document.createElement('a');
        a.href = URL.createObjectURL(blob);
        a.download = fname;
        a.style.display = 'none';
        document.body.appendChild(a);
        a.click();
        setTimeout(function () {
            document.body.removeChild(a);
            URL.revokeObjectURL(a.href);
        }, 0);
        window.__lastSMSRom = rom;
        window.__lastSMSName = fname;
        consolePrint('SMS ROM exported: ' + fname + ' (' + rom.length + ' bytes, ' +
            (rom.length / 16384) + ' banks). Test it in Emulicious, Meka or RetroArch (Genesis Plus GX).');
    } catch (e) {
        if (e instanceof SMSExportError) {
            consolePrint('<span class="errorText">SMS export failed: ' + e.message + '</span>');
        } else {
            consolePrint('<span class="errorText">SMS export failed: ' + (e && e.message) + '</span>');
            throw e;
        }
    }
}

/* Build the ROM (no download) and open it in the embedded EmulatorJS page.
   The ROM is handed to the player window through a Blob URL kept on the
   opener, so nothing touches disk and it works offline for the base ROM
   (only EmulatorJS's own data is fetched from its CDN). */
function playSMSClick() {
    try {
        compile(['restart']);
    } catch (e) { /* compile logs its own errors */ }

    try {
        if (typeof PS_SMS_BASE_ROM_B64 === 'undefined' || PS_SMS_BASE_ROM_B64.indexOf('PLACEHOLDER') === 0)
            throw new SMSExportError('Base ROM missing: run sms/tools/embed_base_rom.py (see sms/README.md).');

        var warnings = [];
        var rom = buildSMSRomFromState(state, b64ToBytes(PS_SMS_BASE_ROM_B64), warnings);
        for (var i = 0; i < warnings.length; i++)
            consolePrint('SMS export warning: ' + warnings[i]);

        var title = (state.metadata.title || 'PuzzleScript game');
        var blob = new Blob([rom], { type: 'application/octet-stream' });
        var url = URL.createObjectURL(blob);

        /* stash for the player window to read via window.opener */
        global.__psSMSPlay = { url: url, title: title };

        var win = window.open('play_sms.html', 'psSMSplayer');
        if (!win) {
            URL.revokeObjectURL(url);
            consolePrint('<span class="errorText">SMS play failed: popup blocked. Allow popups for this site, or use EXPORT SMS.</span>');
            return;
        }
        consolePrint('Launching "' + title + '" in the embedded Sega Master System emulator...');
    } catch (e) {
        if (e instanceof SMSExportError)
            consolePrint('<span class="errorText">SMS play failed: ' + e.message + '</span>');
        else {
            consolePrint('<span class="errorText">SMS play failed: ' + (e && e.message) + '</span>');
            throw e;
        }
    }
}

global.exportSMSClick = exportSMSClick;
global.playSMSClick = playSMSClick;
global.buildSMSRomFromState = buildSMSRomFromState;
global.buildSMSData = buildSMSData;

if (typeof module !== 'undefined' && module.exports) {
    module.exports = { buildSMSData: buildSMSData, buildSMSRomFromState: buildSMSRomFromState };
}

})(typeof window !== 'undefined' ? window : globalThis);
