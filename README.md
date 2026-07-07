PuzzleScript
============

Open Source HTML5 Puzzle Game Engine — with a **Sega Master System ROM exporter**.

Try the upstream engine at https://www.puzzlescript.net.

-----

Running it locally
------------------

PuzzleScript is a static site — it just needs to be served over HTTP (opening
the files with `file://` won't work because the browser blocks some requests).

1. **Start a web server in the project root.**

   * Windows: double-click **`runserver.bat`** (it prints your IP and starts
     `python -m http.server` on port 8000).
   * macOS / Linux: run `python3 -m http.server` in this folder.

2. **Open the editor.** Browse to <http://localhost:8000/> — the root
   [`index.html`](index.html) automatically redirects to the editor at
   `src/editor.html`.

   > Previously the server showed a bare directory listing because there was no
   > page at the root; the redirect fixes that. If you still land on a file
   > list, go straight to <http://localhost:8000/src/editor.html>.

That's it — you can now write, run and share games in the browser.

If you're interested in recompiling / modifying / hacking the engine, there is
[development setup info here](DEVELOPMENT.md). To learn how to *make* games,
[the documentation is here](https://www.puzzlescript.net/Documentation/documentation.html).

-----

Exporting to Sega Master System
-------------------------------

This fork adds two buttons to the editor toolbar:

* **EXPORT SMS** — builds a Sega Master System ROM and downloads it as a
  `.sms` file. Run it in any SMS emulator (Emulicious, Meka, RetroArch with
  Genesis Plus GX / SMS Plus GX) or on real hardware.
* **PLAY SMS** — builds the same ROM and launches it immediately in an
  **embedded emulator** ([EmulatorJS](https://emulatorjs.org)) in a new tab,
  with no download. The ROM is passed in memory; only the emulator runtime is
  streamed from EmulatorJS's CDN, so this button needs an internet connection.
  (Offline? Use **EXPORT SMS** instead.)

Each PuzzleScript object (a 5x5 sprite) is scaled up to a 16x16-pixel tile, so
a level of up to 16x12 cells fills the 256x192 screen. The ROM contains a
generic PuzzleScript runtime written in Z80 C; your game's compiled rules,
graphics and levels are appended as data. Full details, limits and the build
instructions for the runtime are in **[`sms/README.md`](sms/README.md)**.

Command-line export (no browser):

```bash
node sms/tools/export_cli.js src/demo/microban.txt microban.sms
```
