/*
 * PuzzleScript SMS ROM  (v2)
 *
 * All resource data lives in a single 16-KB ROM bank (bank 2, mapped at
 * 0x8000). We keep the bank permanently mapped and use byte offsets via the
 * RD16/RESB macros — never raw C pointers that dangle after a bank switch.
 *
 * Resource layout (appended after the 32-KB code ROM):
 *   "rsc\0" + u16 file_count
 *   file_count × 20-byte entries: char name[14], u16 page, u16 size, u16 offset
 *   ...file data tightly packed...
 *
 * Files:
 *   ps.pal  16 SMS palette bytes
 *   ps.til  blank(128 B) + N×128 B per PS object (4 SMS tiles each)
 *   ps.lvl  u16 levelCount; per level: u16 w,h,stateCount; stateCount×(w*h) u8
 *   ps.trn  per level: u16 stateCount; per state: u16×5 next + u8 win
 *   ps.inf  null-terminated project title
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "SMSlib.h"
#include "PSGlib.h"

/* ── Constants ───────────────────────────────────────────────────── */
#define RES_BANK      2
#define RES_BASE      0x8000u
#define MAX_CELLS     144       /* 16×9 */
#define MAX_STATES    256
#define UNDO_DEPTH    32

#define INP_UP        0
#define INP_LEFT      1
#define INP_DOWN      2
#define INP_RIGHT     3
#define INP_ACTION    4
#define INP_COUNT     5
#define INP_NONE      0xFF
#define INP_UNDO      0xFE
#define NO_TRANS      0xFFFFu

/* Resource filesystem constants */
#define HDR_SIZE      6         /* "rsc\0" + u16 count */
#define ENTRY_SIZE    20        /* name(14)+page(2)+size(2)+offset(2) */

/* ── Macros ──────────────────────────────────────────────────────── */
#define RESB          ((unsigned char*)RES_BASE)
#define RD16(off)     ((unsigned int)(RESB[off]) | ((unsigned int)(RESB[(off)+1])<<8))

/* ── Globals ─────────────────────────────────────────────────────── */
static unsigned char  board[MAX_CELLS];
static unsigned int   level_w, level_h, cells_stride;
static unsigned int   lvl_cells_off;   /* offset of state-0 cell data */
static unsigned int   cur_state, total_levels, cur_level;

typedef struct { unsigned int next[INP_COUNT]; unsigned char win; } trans_t;
static trans_t  trans[MAX_STATES];
static unsigned int  n_trans;

static unsigned int  undo_stk[UNDO_DEPTH];
static unsigned int  undo_top;

/* ── Resource lookup ─────────────────────────────────────────────── */
static unsigned int res_find(const char *name) {
    unsigned int i, base, count;
    count = RD16(4);   /* file_count at byte 4 */
    base  = HDR_SIZE;
    for (i = 0; i < count; i++, base += ENTRY_SIZE) {
        if (strncmp((char*)(RESB+base), name, 13) == 0)
            return RD16(base + 14 + 2 + 2); /* offset field */
    }
    return 0;
}

static unsigned int res_size(const char *name) {
    unsigned int i, base, count;
    count = RD16(4);
    base  = HDR_SIZE;
    for (i = 0; i < count; i++, base += ENTRY_SIZE) {
        if (strncmp((char*)(RESB+base), name, 13) == 0)
            return RD16(base + 14 + 2); /* size field */
    }
    return 0;
}

/* ── Board I/O ───────────────────────────────────────────────────── */
static void load_board(unsigned int idx) {
    unsigned int src = lvl_cells_off + idx * cells_stride;
    unsigned int i;
    for (i = 0; i < cells_stride; i++) board[i] = RESB[src+i];
    cur_state = idx;
}

/* ── Level load ──────────────────────────────────────────────────── */
static void load_level(unsigned int lv_num) {
    unsigned int p, t, lv, s, i, w, h, sc;

    cur_level = lv_num;
    undo_top  = 0;

    /* Walk ps.lvl */
    p = res_find("ps.lvl");
    total_levels = RD16(p); p += 2;
    for (lv = 0; lv < lv_num; lv++) {
        w  = RD16(p); p += 2;
        h  = RD16(p); p += 2;
        sc = RD16(p); p += 2;
        p += (unsigned int)sc * w * h;
    }
    level_w          = RD16(p); p += 2;
    level_h          = RD16(p); p += 2;
    sc               = RD16(p); p += 2;
    cells_stride     = level_w * level_h;
    lvl_cells_off    = p;
    load_board(0);

    /* Walk ps.trn */
    t = res_find("ps.trn");
    for (lv = 0; lv < lv_num; lv++) {
        sc = RD16(t); t += 2;
        t += (unsigned int)sc * (INP_COUNT * 2 + 1);
    }
    n_trans = RD16(t); t += 2;
    if (n_trans > MAX_STATES) n_trans = MAX_STATES;
    for (s = 0; s < n_trans; s++) {
        for (i = 0; i < INP_COUNT; i++) { trans[s].next[i] = RD16(t); t += 2; }
        trans[s].win = RESB[t]; t++;
    }
}

/* ── Graphics ────────────────────────────────────────────────────── */
static void load_gfx(void) {
    unsigned int off;
    off = res_find("ps.pal");
    SMS_loadBGPalette((void*)(RESB+off));
    SMS_loadSpritePalette((void*)(RESB+off));
    off = res_find("ps.til");
    SMS_loadTiles((void*)(RESB+off), 0, res_size("ps.til"));
}

static void draw_board(void) {
    unsigned int col, row, obj, base, tx, ty;
    for (row = 0; row < level_h; row++) {
        for (col = 0; col < level_w; col++) {
            obj  = board[col + row * level_w];
            base = obj * 4;
            tx   = col * 2;
            ty   = row * 2 + 2;
            SMS_setNextTileatXY(tx,   ty);   SMS_setTile(base);
            SMS_setNextTileatXY(tx+1, ty);   SMS_setTile(base+1);
            SMS_setNextTileatXY(tx,   ty+1); SMS_setTile(base+2);
            SMS_setNextTileatXY(tx+1, ty+1); SMS_setTile(base+3);
        }
    }
}

/* ── Input ───────────────────────────────────────────────────────── */
static unsigned char get_new_input(unsigned int *prev) {
    unsigned int joy = SMS_getKeysStatus(), newly = joy & ~(*prev);
    *prev = joy;
    if (newly & PORT_A_KEY_UP)    return INP_UP;
    if (newly & PORT_A_KEY_LEFT)  return INP_LEFT;
    if (newly & PORT_A_KEY_DOWN)  return INP_DOWN;
    if (newly & PORT_A_KEY_RIGHT) return INP_RIGHT;
    if (newly & (PORT_A_KEY_1|PORT_B_KEY_1)) return INP_ACTION;
    if (newly & (PORT_A_KEY_2|PORT_B_KEY_2)) return INP_UNDO;
    return INP_NONE;
}

static void wait_new_key(void) {
    unsigned int prev = SMS_getKeysStatus();
    while (1) {
        SMS_waitForVBlank();
        unsigned int joy = SMS_getKeysStatus();
        if ((joy & ~prev) & 0x00FF) return;
        prev = joy;
    }
}

/* ── Screens ─────────────────────────────────────────────────────── */
static void show_title(void) {
    unsigned int off = res_find("ps.inf");
    SMS_VRAMmemsetW(0, 0, 16*1024);
    SMS_setNextTileatXY(2,4);
    if (off) puts((char*)(RESB+off)); else puts("PuzzleScript");
    SMS_setNextTileatXY(2,8); puts("Press any button");
    SMS_displayOn();
    wait_new_key();
}

static void show_level_clear(void) {
    SMS_VRAMmemsetW(0, 0, 16*1024);
    SMS_setNextTileatXY(4,6); puts("Level Clear!");
    SMS_setNextTileatXY(3,9); puts("Press any button");
    SMS_displayOn();
    wait_new_key();
}

static void show_you_win(void) {
    SMS_VRAMmemsetW(0, 0, 16*1024);
    SMS_setNextTileatXY(6,5); puts("You Win!");
    SMS_setNextTileatXY(3,8); puts("Press any button");
    SMS_setNextTileatXY(4,10); puts("to play again");
    SMS_displayOn();
    wait_new_key();
}

/* ── Main ────────────────────────────────────────────────────────── */
void main(void) {
    unsigned int lv, prev_joy, next_st;
    unsigned char inp;

    SMS_useFirstHalfTilesforSprites(1);
    SMS_mapROMBank(RES_BANK);   /* map once, stay there */

    SMS_waitForVBlank();
    SMS_displayOff();
    SMS_VRAMmemsetW(0, 0, 16*1024);
    load_gfx();
    total_levels = RD16(res_find("ps.lvl"));

    show_title();

    lv = 0;
    while (1) {
        if (lv >= total_levels) { show_you_win(); lv = 0; }

        load_level(lv);
        undo_stk[0] = 0; undo_top = 1;

        SMS_waitForVBlank();
        SMS_displayOff();
        SMS_VRAMmemsetW(0, 0, 16*1024);
        SMS_setNextTileatXY(0,0);
        printf("Lv%d/%d  2=undo", lv+1, total_levels);
        draw_board();
        SMS_displayOn();

        prev_joy = SMS_getKeysStatus();

        while (1) {
            SMS_waitForVBlank();
            inp = get_new_input(&prev_joy);
            if (inp == INP_NONE) continue;

            if (inp == INP_UNDO) {
                if (undo_top > 1) {
                    undo_top--;
                    load_board(undo_stk[undo_top-1]);
                    draw_board();
                }
                continue;
            }

            if (inp >= INP_COUNT) continue;

            next_st = trans[cur_state].next[inp];
            if (next_st == NO_TRANS || next_st >= n_trans) continue;

            if (undo_top < UNDO_DEPTH) undo_stk[undo_top++] = next_st;
            load_board(next_st);
            draw_board();

            if (trans[cur_state].win) {
                show_level_clear();
                lv++;
                break;
            }
        }
    }
}

SMS_EMBED_SEGA_ROM_HEADER(9999, 0);
SMS_EMBED_SDSC_HEADER(2, 0, 2025, 01, 01,
    "PuzzleScript-SMS", "PuzzleScript SMS ROM v2",
    "Transpiled PuzzleScript for Sega Master System.");
