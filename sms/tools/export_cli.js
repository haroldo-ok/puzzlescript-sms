#!/usr/bin/env node
/* ============================================================================
   export_cli.js — compile a PuzzleScript game headlessly and export a Sega
   Master System ROM.

       node sms/tools/export_cli.js <game.txt> [out.sms]

   Reuses the same browser shims as src/tests/run_tests_node.js so the real
   compiler (parser.js/compiler.js/engine.js) runs unmodified, then feeds the
   compiled state to src/js/exportsms.js and appends the base ROM.
   ========================================================================= */
'use strict';

const fs = require('fs');
const vm = require('vm');
const path = require('path');

const root = path.join(__dirname, '..', '..');
const srcDir = path.join(root, 'src');

const gameFile = process.argv[2];
if (!gameFile) {
    console.error('usage: node sms/tools/export_cli.js <game.txt> [out.sms]');
    process.exit(1);
}
const outFile = process.argv[3] ||
    path.join(path.dirname(gameFile), path.basename(gameFile).replace(/\.txt$/i, '') + '.sms');

/* ---- browser shims (mirrors src/tests/run_tests_node.js) ---- */
const _storage = {};
global.localStorage = {
    getItem(k) { return _storage.hasOwnProperty(k) ? _storage[k] : null; },
    setItem(k, v) { _storage[k] = String(v); },
    removeItem(k) { delete _storage[k]; }
};
global.document = {
    URL: 'export://',
    body: { classList: { contains() { return false; } }, addEventListener() {}, removeEventListener() {} },
    createElement() { return { style: {}, innerHTML: '', textContent: '', getContext() { return null; } }; },
    getElementById() { return null; }
};
global.window = global;
global.lastDownTarget = null;
global.canvas = null;
global.input = global.document.createElement('TEXTAREA');
global.canvasResize = function () {};
global.redraw = function () {};
global.forceRegenImages = function () {};
global.consolePrintFromRule = function () {};
let compileErrors = [];
global.consolePrint = function (t) {
    const plain = String(t).replace(/<[^>]*>/g, '');
    if (/error/i.test(plain)) compileErrors.push(plain);
    if (process.env.VERBOSE) console.log('[ps]', plain);
};
global.console_print_raw = console.log;
global.consoleError = function (t) { compileErrors.push(String(t).replace(/<[^>]*>/g, '')); };
global.consoleCacheDump = function () {};
global.addToDebugTimeline = function () {};
global.killAudioButton = function () {};
global.showAudioButton = function () {};
global.regenSpriteImages = function () {};
global.jumpToLine = function () {};
global.printLevel = function () {};
global.playSound = function () {};
global.levelString = '';
global.editor = { getValue() { return global.levelString; } };
global.QUnit = { push() {}, assert: { equal() {} } };
global.UnitTestingThrow = function (e) { throw e; };

/* ---- load engine + compiler in one shared scope ---- */
const sourceFiles = [
    'js/storagewrapper.js', 'js/bitvec.js', 'js/level.js', 'js/languageConstants.js',
    'js/globalVariables.js', 'js/debug.js', 'js/font.js', 'js/rng.js', 'js/riffwave.js',
    'js/sfxr.js', 'js/codemirror/stringstream.js', 'js/colors.js', 'js/engine.js',
    'js/parser.js', 'js/compiler.js', 'js/soundbar.js', 'js/exportsms.js',
];
let allCode = '';
for (const f of sourceFiles)
    allCode += `\n// ---- ${f} ----\n` + fs.readFileSync(path.join(srcDir, f), 'utf8') + '\n';
allCode += '\nglobal.__compileGame = function(src){ global.levelString = src; compile(["restart"], src); return state; };\n';
vm.runInThisContext(allCode, { filename: 'combined_sources.js' });

/* ---- compile ---- */
const source = fs.readFileSync(gameFile, 'utf8');
const state = global.__compileGame(source);
if (compileErrors.length) {
    console.error('PuzzleScript compile errors:');
    for (const e of compileErrors) console.error('  ' + e);
    process.exit(1);
}

/* ---- export ---- */
const baseB64 = require(path.join(srcDir, 'js', 'sms_base_rom.js'));
const baseRom = new Uint8Array(Buffer.from(baseB64, 'base64'));
const warnings = [];
let rom;
try {
    rom = global.buildSMSRomFromState(state, baseRom, warnings);
} catch (e) {
    console.error('SMS export failed: ' + (e.message || e)); if (process.env.TRACE) console.error(e.stack);
    process.exit(1);
}
for (const w of warnings) console.warn('warning: ' + w);
fs.writeFileSync(outFile, Buffer.from(rom));
console.log(`wrote ${outFile}  (${rom.length} bytes, ${rom.length / 16384} banks, ` +
            `${state.objectCount} objects, ${state.levels.length} levels)`);
