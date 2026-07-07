# PuzzleScript → Sega Master System export

This directory adds a **Sega Master System ROM exporter** to PuzzleScript.

* Click **EXPORT SMS** in the editor toolbar (next to EXPORT) and you get a
  `.sms` file that runs on real hardware and in any SMS emulator
  (Emulicious, Meka, RetroArch/Genesis Plus GX, BlastEm...).
* Click **PLAY SMS** to build the same ROM and boot it straight away in an
  embedded [EmulatorJS](https://emulatorjs.org) player (opens `src/play_sms.html`
  in a new tab). The ROM is handed over in memory as a Blob URL — nothing is
  written to disk — but the emulator runtime is fetched from
  `cdn.emulatorjs.org`, so this needs an internet connection. Offline, use
  EXPORT SMS and open the file in a native emulator.

There is also a command-line exporter:

```bash
node sms/tools/export_cli.js src/demo/microban.txt microban.sms
```

## How it works

The exporter does **not** transpile your rules to Z80 code. Instead, the
32 KB base ROM (`sms/base-rom/ps_engine.c`) is a generic **PuzzleScript
runtime re-implemented in C for the Z80**, and the exporter serialises the
*compiled* engine state — the exact same bitmask representation that
`src/js/engine.js` executes — into data banks appended after the base ROM:

```
banks 0-1   Z80 engine (SDCC + devkitSMS), 32 KB, fixed
banks 2+    game data: header, palette, object graphics, rule bytecode,
            win conditions, levels, message strings (16 KB pages,
            standard Sega mapper, paged at 0x8000)
```

The Z80 engine mirrors the PuzzleScript turn pipeline:

* cells are 32-bit object bitmasks; movements are 5 bits per collision layer
* cell patterns match `objectsPresent / objectsMissing / anyObjectsPresent /
  movementsPresent / movementsMissing`; replacements apply
  `new = (old & ~clear) | set` to both objects and movements
* rule groups loop until stable → movement resolution loops until stable →
  late rules → commands → win conditions — the same order as `engine.js`
* commands: `cancel restart win again checkpoint message`
* an undo ring (3 turns), tap-2 to undo, hold-2 to restart, checkpoints

### Graphics: 5×5 sprites → 16×16 tiles

Every PuzzleScript object is scaled from 5×5 to **16×16 pixels**
(nearest-neighbour), i.e. one cell = 2×2 hardware tiles, so a maximum level
of 16×12 cells fills the 256×192 screen. Objects are stored with a
per-pixel transparency mask (8 rows × [mask + 4 bitplanes] × 4 subtiles =
160 bytes/object) and the engine **composites stacked objects
bottom-to-top at runtime**, caching each distinct cell combination in VRAM
(up to 86 combinations per level). All object colours are quantised to the
SMS's 64-colour master palette and packed into one 16-colour palette
(index 0 = `background_color`, index 15 = `text_color`).

### Controls

| Input        | Action                                   |
|--------------|-------------------------------------------|
| D-pad        | move (with hold-repeat)                    |
| Button 1     | action (X) / advance title & messages      |
| Button 2 tap | undo                                       |
| Button 2 hold (1 s) | restart level / return to checkpoint |

## Supported subset

Exports fail with a clear message (or warn) when a game exceeds the
engine's limits:

| Feature | Limit |
|---|---|
| objects | ≤ 32 |
| collision layers | ≤ 6 |
| level size | ≤ 16×12 cells |
| levels | ≤ 255 (message "levels" supported) |
| ellipsis rules `[ a | ... | b ]` | **not supported** |
| `realtime_interval` | **not supported** |
| rigid bodies | exported as non-rigid (warning) |
| `startloop/endloop` | groups run sequentially (warning) |
| random rules / `randomDir` / `random` objects | supported (8-bit RNG) |
| `flickscreen` / `zoomscreen` | ignored (warning) |
| sounds | ignored |
| single data blob (rules, one level, gfx) | ≤ 16 KB (one bank) |

34 of the 94 games in `src/demo/` export out of the box, including
`microban`, `zenpuzzlegarden`, `sokobond demake`, `modality`,
`lunar_lockout` and `notsnake`.

## Layout

```
sms/
  base-rom/
    ps_engine.c     the PuzzleScript runtime for Z80 (fully commented,
                    includes the game-data format specification)
    font.c          96-glyph 1bpp font (from SMS-Puzzle-Maker, MIT)
    Makefile        build with SDCC ≥ 4.x + devkitSMS's ihx2sms
    lib/            SMSlib.h/.lib, crt0_sms.rel, peep-rules.txt (devkitSMS)
    ps_base_rom.sms prebuilt 32 KB base ROM
  tools/
    embed_base_rom.py  regenerates src/js/sms_base_rom.js after `make`
    export_cli.js      headless .txt → .sms exporter (node)
    smsrun.js          headless SMS emulator harness for testing ROMs
    get_z80js.sh       fetches the MIT Z80 core smsrun.js needs
src/js/exportsms.js    the exporter (used by the editor and export_cli)
src/js/sms_base_rom.js base ROM as base64 (auto-generated)
src/play_sms.html      embedded EmulatorJS player (opened by PLAY SMS)
index.html             (repo root) redirects to src/editor.html
```

## Rebuilding the base ROM

```bash
sudo apt install sdcc
gcc -O2 -o ihx2sms devkitSMS/ihx2sms/src/ihx2sms.c   # from sverx/devkitSMS
cd sms/base-rom && make IHX2SMS=path/to/ihx2sms
cd ../.. && python3 sms/tools/embed_base_rom.py
```

## Testing ROMs headlessly

```bash
cd sms/tools && ./get_z80js.sh
node smsrun.js game.sms "180,1:5,90,shot,R:4,60,shot" out
# script: N=run N frames, U/D/L/R/1/2:N=hold input N frames, shot=screenshot
# emits out_NN.ppm (pixels) and out_NN.txt (tilemap as ASCII)
```

## A note on SDCC

`ps_engine.c` deliberately passes ROM cursors **by value and returns the
advanced pointer**. SDCC 4.2 (`-mz80 --opt-code-speed`) mis-compiles loops
around calls that mutate a stack local through an escaped pointer
(`f(&p)`): the loop-top re-initialisation of `p` is elided. Keep that
style if you modify the parser.

## Credits

* [devkitSMS / SMSlib](https://github.com/sverx/devkitSMS) — sverx
* Font from [SMS-Puzzle-Maker](https://github.com/haroldo-ok/SMS-Puzzle-Maker) — Haroldo-OK (MIT)
* [Z80.js](https://github.com/DrGoldfire/Z80.js) (test harness only) — Molly Howell (MIT)
* [PuzzleScript](https://www.puzzlescript.net) — increpare
