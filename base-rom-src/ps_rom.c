/*
 * PuzzleScript SMS ROM
 * Table-driven PuzzleScript engine for the Sega Master System.
 *
 * Game logic is NOT hardcoded here. The JS transpiler bakes all PuzzleScript
 * rule outcomes into resource data files at export time. This C program simply:
 *   1. Renders the current level state as tiles
 *   2. Reads d-pad input
 *   3. Looks up the next state in the transition table
 *   4. Checks the win table
 *   5. Advances to the next level on win
 *
 * Resource files consumed:
 *   ps.pal   - SMS palette (16 bytes)
 *   ps.til   - SMS tile data (N * 128 bytes, each PS object = 2x2 SMS tiles)
 *   ps.lvl   - Level definitions (see struct below)
 *   ps.trn   - Transition tables per level (see struct below)
 *   ps.win   - Win condition tables per level
 *   ps.inf   - Project name string (null-terminated)
 *
 * Level format (ps.lvl):
 *   u16 levelCount
 *   for each level:
 *     u16 width, u16 height
 *     u16 stateCount          -- number of distinct cell states in this level
 *     u8  cells[width*height] -- initial tile index per cell (0=empty)
 *
 * Transition format (ps.trn):
 *   for each level:
 *     u16 stateCount   -- must match ps.lvl
 *     for each state (stateCount entries):
 *       u8 next[5]     -- next state index for inputs: up/left/down/right/action
 *                         0xFF = no change / blocked
 *       u8 win         -- 1 if this state is a win state, 0 otherwise
 *
 * Cell state (ps.lvl cells[]):
 *   Each byte encodes one cell.  Value = index into the object list (1-based).
 *   0 = empty (background).  The tile rendered = (objectIndex * 4) for the
 *   top-left 8x8 quad of that object's 16x16 tile.
 *
 * State representation on the SMS:
 *   We represent the entire board as a flat array of u8 cell values.
 *   A "state index" is an index into a level-specific table of known board
 *   configurations. The transpiler enumerates all reachable states at export
 *   time (BFS from the initial state), assigns each an index, and writes the
 *   transition table.  The SMS only ever stores the current state index (u16).
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "lib/SMSlib.h"
#include "lib/PSGlib.h"

/* ── Hardware / layout constants ──────────────────────────────────────────── */
#define SCREEN_W        256
#define SCREEN_H        192
#define TILE_PIX        16      /* PS tile = 16x16 pixels                     */
#define SMS_TILE        8       /* SMS hardware tile = 8x8 pixels             */
#define PS_TILES_PER_ROW  16    /* max map width in PS tiles                  */
#define PS_TILES_PER_COL   9    /* max map height in PS tiles                 */
#define MAP_OFF_X         0     /* pixel offset of map on screen              */
#define MAP_OFF_Y         0
#define MAP_CHAR_OFF_X    0     /* char (8px) column of map                   */
#define MAP_CHAR_OFF_Y    2     /* leave two rows for level number HUD        */

/* ── Resource bank ────────────────────────────────────────────────────────── */
#define RESOURCE_BANK       2
#define RESOURCE_BASE_ADDR  0x8000

/* ── Input bit masks ──────────────────────────────────────────────────────── */
#define INPUT_UP     0
#define INPUT_LEFT   1
#define INPUT_DOWN   2
#define INPUT_RIGHT  3
#define INPUT_ACTION 4
#define INPUT_NONE   0xFF

/* ── Resource filesystem (identical to SMS-Puzzle-Maker) ───────────────────── */
typedef struct {
    char            signature[4];
    unsigned int    file_count;
} resource_header_t;

typedef struct {
    char            name[14];
    unsigned int    page;
    unsigned int    size;
    unsigned int    offset;
} resource_entry_t;

const resource_header_t *res_hdr  = (resource_header_t*)RESOURCE_BASE_ADDR;
const resource_entry_t  *res_ents = (resource_entry_t*)(RESOURCE_BASE_ADDR + sizeof(resource_header_t));

/* ── In-RAM level state ───────────────────────────────────────────────────── */
#define MAX_CELLS  (PS_TILES_PER_ROW * PS_TILES_PER_COL)  /* 144 */
#define MAX_STATES 512   /* max reachable states per level in RAM             */

/* Current board = array of cell values loaded from the active state entry */
static unsigned char board[MAX_CELLS];

/* Loaded level metadata */
static unsigned int  level_width;
static unsigned int  level_height;
static unsigned int  level_state_count;  /* number of distinct states        */
static unsigned int  cur_state_index;    /* index of current state           */
static unsigned int  cur_level;          /* 0-based level number             */
static unsigned int  total_levels;

/* Transition table entry: 5 next-state indices + win flag (6 bytes) */
typedef struct {
    unsigned int next[5];   /* next state for each of the 5 inputs           */
    unsigned char win;      /* 1 = winning state                              */
} trans_entry_t;

/* We load the transition table for the current level into RAM. */
/* MAX_STATES * sizeof(trans_entry_t) = 512 * 11 = 5632 bytes — fits in SMS RAM */
static trans_entry_t trans[MAX_STATES];

/* State cell data: each state is MAX_CELLS bytes */
/* 512 * 144 = 73728 bytes — too large for RAM! We keep only the current     */
/* board in RAM and re-load from ROM when we need to display after transition */
/* So instead we store state cell data in ROM and index into it.              */

/* ── ROM pointers (set during level load) ─────────────────────────────────── */
static unsigned char *cells_rom_base;  /* pointer into ROM page for cells data */
static unsigned int   cells_stride;    /* bytes per state = width*height        */

/* ── Resource lookup ──────────────────────────────────────────────────────── */
static resource_entry_t* res_find(const char *name) {
    unsigned int remaining;
    resource_entry_t *entry;

    SMS_mapROMBank(RESOURCE_BANK);
    remaining = res_hdr->file_count;
    entry     = (resource_entry_t*)res_ents;

    while (remaining--) {
        if (!strcmp(name, entry->name)) return entry;
        entry++;
    }
    return 0;
}

static unsigned char* res_ptr(resource_entry_t *entry) {
    if (!entry) return 0;
    SMS_mapROMBank(entry->page);
    return (unsigned char*)(RESOURCE_BASE_ADDR + entry->offset);
}

/* ── Graphics helpers ─────────────────────────────────────────────────────── */
static void load_palette(void) {
    unsigned char *pal = res_ptr(res_find("ps.pal"));
    if (pal) SMS_loadBGPalette(pal);
}

static void load_tiles(void) {
    resource_entry_t *e = res_find("ps.til");
    if (!e) return;
    unsigned char *til = res_ptr(e);
    /* Each PS object occupies 4 SMS tiles (2×2 arrangement), 32 bytes each.
       Tile 0 = blank background (128 zero bytes already in the file).        */
    SMS_loadTiles(til, 0, e->size);
}

/*
 * Draw the current board to the SMS name table.
 * Each PS cell at (col, row) maps to a 2×2 block of SMS name table entries
 * starting at char position (MAP_CHAR_OFF_X + col*2, MAP_CHAR_OFF_Y + row*2).
 *
 * SMS tile index for PS object N (1-based):
 *   base = N * 4          (4 SMS tiles per PS tile)
 *   TL = base+0, TR = base+1, BL = base+2, BR = base+3
 */
static void draw_board(void) {
    unsigned int col, row, cell_idx;
    unsigned char obj;
    unsigned int sms_base, tx, ty;

    for (row = 0; row < level_height; row++) {
        for (col = 0; col < level_width; col++) {
            cell_idx = col + row * level_width;
            obj = board[cell_idx];
            sms_base = (unsigned int)obj * 4;
            tx = MAP_CHAR_OFF_X + col * 2;
            ty = MAP_CHAR_OFF_Y + row * 2;
            SMS_setNextTileatXY(tx,     ty);     SMS_setTile(sms_base);
            SMS_setNextTileatXY(tx + 1, ty);     SMS_setTile(sms_base + 1);
            SMS_setNextTileatXY(tx,     ty + 1); SMS_setTile(sms_base + 2);
            SMS_setNextTileatXY(tx + 1, ty + 1); SMS_setTile(sms_base + 3);
        }
    }
}

/* Clear the map area to tile 0 (background) */
static void clear_map(void) {
    unsigned int tx, ty;
    for (ty = MAP_CHAR_OFF_Y; ty < MAP_CHAR_OFF_Y + PS_TILES_PER_COL * 2; ty++) {
        for (tx = MAP_CHAR_OFF_X; tx < MAP_CHAR_OFF_X + PS_TILES_PER_ROW * 2; tx++) {
            SMS_setNextTileatXY(tx, ty);
            SMS_setTile(0);
        }
    }
}

/* ── Level loading ────────────────────────────────────────────────────────── */

/*
 * ps.lvl binary layout:
 *   u16 total_levels
 *   for each level:
 *     u16 width
 *     u16 height
 *     u16 state_count
 *     u8  initial_cells[width * height]   ← state index 0
 *     u8  state1_cells [width * height]   ← state index 1
 *     ...
 *     u8  stateN_cells [width * height]
 *
 * ps.trn binary layout:
 *   for each level (same count as ps.lvl):
 *     for each state (state_count entries):
 *       u16 next_up, next_left, next_down, next_right, next_action
 *       u8  is_win
 *       (total 11 bytes per entry)
 */
static void load_level(unsigned int level_num) {
    resource_entry_t *lvl_entry, *trn_entry;
    unsigned char *p;
    unsigned int lv, state, i;
    unsigned int width, height, state_count, stride;

    cur_level    = level_num;
    cur_state_index = 0;

    /* ── locate ps.lvl and skip to our level ── */
    lvl_entry = res_find("ps.lvl");
    if (!lvl_entry) return;
    p = res_ptr(lvl_entry);

    total_levels = *(unsigned int*)p; p += 2;

    for (lv = 0; lv < level_num; lv++) {
        width       = *(unsigned int*)p; p += 2;
        height      = *(unsigned int*)p; p += 2;
        state_count = *(unsigned int*)p; p += 2;
        stride = width * height;
        p += state_count * stride;   /* skip all state data for this level */
    }

    level_width       = *(unsigned int*)p; p += 2;
    level_height      = *(unsigned int*)p; p += 2;
    level_state_count = *(unsigned int*)p; p += 2;
    cells_stride      = level_width * level_height;
    cells_rom_base    = p;   /* pointer to first state's cell data in ROM    */

    /* Load initial board (state 0) into RAM */
    SMS_mapROMBank(lvl_entry->page);
    for (i = 0; i < cells_stride; i++) {
        board[i] = cells_rom_base[i];
    }

    /* ── locate ps.trn and skip to our level ── */
    trn_entry = res_find("ps.trn");
    if (!trn_entry) return;
    p = res_ptr(trn_entry);

    /* Each entry = 5 * u16 + u8 = 11 bytes */
#define ENTRY_SIZE 11
    for (lv = 0; lv < level_num; lv++) {
        unsigned int sc;
        /* read state_count for this level from the transition block header */
        sc = *(unsigned int*)p; p += 2;
        p += sc * ENTRY_SIZE;
    }

    /* state_count for this level is at the start of its transition block */
    {
        unsigned int sc = *(unsigned int*)p; p += 2;
        /* Load all transitions into RAM */
        for (state = 0; state < sc && state < MAX_STATES; state++) {
            for (i = 0; i < 5; i++) {
                trans[state].next[i] = *(unsigned int*)p; p += 2;
            }
            trans[state].win = *p; p++;
        }
    }
}

/* Reload the board for the current state index from ROM */
static void restore_board_from_state(void) {
    unsigned int i;
    unsigned char *src;
    resource_entry_t *e = res_find("ps.lvl");
    if (!e) return;
    SMS_mapROMBank(e->page);
    src = cells_rom_base + (unsigned long)cur_state_index * cells_stride;
    for (i = 0; i < cells_stride; i++) {
        board[i] = src[i];
    }
}

/* ── Input ────────────────────────────────────────────────────────────────── */
static unsigned char read_input(void) {
    unsigned int joy = SMS_getKeysStatus();
    if (joy & PORT_A_KEY_UP)    return INPUT_UP;
    if (joy & PORT_A_KEY_LEFT)  return INPUT_LEFT;
    if (joy & PORT_A_KEY_DOWN)  return INPUT_DOWN;
    if (joy & PORT_A_KEY_RIGHT) return INPUT_RIGHT;
    if (joy & (PORT_A_KEY_1 | PORT_A_KEY_2)) return INPUT_ACTION;
    return INPUT_NONE;
}

static void wait_key_release(void) {
    while (SMS_getKeysStatus() & (PORT_A_KEY_UP|PORT_A_KEY_LEFT|
                                  PORT_A_KEY_DOWN|PORT_A_KEY_RIGHT|
                                  PORT_A_KEY_1|PORT_A_KEY_2|
                                  PORT_B_KEY_1|PORT_B_KEY_2)) {
        SMS_waitForVBlank();
    }
}

static void wait_any_key(void) {
    while (!(SMS_getKeysStatus() & (PORT_A_KEY_UP|PORT_A_KEY_LEFT|
                                    PORT_A_KEY_DOWN|PORT_A_KEY_RIGHT|
                                    PORT_A_KEY_1|PORT_A_KEY_2|
                                    PORT_B_KEY_1|PORT_B_KEY_2))) {
        SMS_waitForVBlank();
    }
}

/* ── HUD ──────────────────────────────────────────────────────────────────── */
static void draw_hud(void) {
    SMS_setNextTileatXY(0, 0);
    printf("Level %d/%d", cur_level + 1, total_levels);
}

/* ── Title / win screens ──────────────────────────────────────────────────── */
static void show_title(void) {
    resource_entry_t *e;
    unsigned char *name;

    SMS_waitForVBlank();
    SMS_displayOff();
    SMS_VRAMmemsetW(0, 0, 16 * 1024);

    e = res_find("ps.inf");
    name = e ? res_ptr(e) : (unsigned char*)"PuzzleScript";

    SMS_setNextTileatXY(2, 4);
    puts((char*)name);
    SMS_setNextTileatXY(2, 8);
    puts("Press any button");

    SMS_displayOn();
    wait_any_key();
    wait_key_release();
}

static void show_win_screen(void) {
    SMS_waitForVBlank();
    SMS_displayOff();
    SMS_VRAMmemsetW(0, 0, 16 * 1024);
    SMS_setNextTileatXY(4, 6);
    puts("Level Complete!");
    SMS_setNextTileatXY(4, 9);
    puts("Press any button");
    SMS_displayOn();
    wait_any_key();
    wait_key_release();
}

static void show_game_over(void) {
    SMS_waitForVBlank();
    SMS_displayOff();
    SMS_VRAMmemsetW(0, 0, 16 * 1024);
    SMS_setNextTileatXY(5, 6);
    puts("You Win!");
    SMS_setNextTileatXY(3, 9);
    puts("Press any button");
    puts("to play again");
    SMS_displayOn();
    wait_any_key();
    wait_key_release();
}

/* ── Undo stack (simple single-level undo) ────────────────────────────────── */
#define UNDO_DEPTH 64
static unsigned int undo_stack[UNDO_DEPTH];
static unsigned int undo_top;

static void undo_push(unsigned int state) {
    if (undo_top < UNDO_DEPTH) undo_stack[undo_top++] = state;
}

static unsigned int undo_pop(void) {
    if (undo_top > 0) return undo_stack[--undo_top];
    return cur_state_index; /* nothing to undo */
}

/* ── Main game loop ───────────────────────────────────────────────────────── */
static void init_graphics(void) {
    SMS_waitForVBlank();
    SMS_displayOff();
    SMS_VRAMmemsetW(0, 0, 16 * 1024);
    load_palette();
    load_tiles();
}

void main(void) {
    unsigned char input, prev_input;
    unsigned int next_state;
    unsigned int lv;

    SMS_useFirstHalfTilesforSprites(1);

    /* Load palette + tiles once */
    init_graphics();

    show_title();

    for (lv = 0; lv < 255; ) {
        /* Load level */
        load_level(lv);
        if (lv >= total_levels) {
            show_game_over();
            lv = 0;
            continue;
        }
        undo_top = 0;
        undo_push(0); /* push initial state */

        /* Draw initial state */
        SMS_waitForVBlank();
        SMS_displayOff();
        SMS_VRAMmemsetW(0, 0, 16 * 1024);
        draw_hud();
        clear_map();
        draw_board();
        SMS_displayOn();

        prev_input = INPUT_NONE;

        /* Per-level game loop */
        while (1) {
            SMS_waitForVBlank();
            input = read_input();

            /* Debounce: only act on a newly pressed key */
            if (input == prev_input || input == INPUT_NONE) {
                prev_input = input;
                continue;
            }
            prev_input = input;

            /* Check undo (button 2 = undo) */
            if (SMS_getKeysStatus() & (PORT_A_KEY_2 | PORT_B_KEY_2)) {
                cur_state_index = undo_pop();
                restore_board_from_state();
                clear_map();
                draw_board();
                continue;
            }

            /* Look up next state */
            next_state = trans[cur_state_index].next[input];
            if (next_state == 0xFFFF) {
                /* No change — blocked input */
                continue;
            }

            /* Push undo, advance state */
            undo_push(cur_state_index);
            cur_state_index = next_state;
            restore_board_from_state();
            clear_map();
            draw_board();

            /* Check win */
            if (trans[cur_state_index].win) {
                show_win_screen();
                lv++;
                break;
            }
        }
    }
}

SMS_EMBED_SEGA_ROM_HEADER(9999, 0);
SMS_EMBED_SDSC_HEADER(1, 0, 2025, 01, 01,
    "PuzzleScript-SMS",
    "PuzzleScript SMS Exporter",
    "Transpiled PuzzleScript game for Sega Master System.");
