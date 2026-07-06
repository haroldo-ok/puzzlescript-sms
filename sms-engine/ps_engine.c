/* ============================================================================
   PuzzleScript engine for the Sega Master System
   ----------------------------------------------------------------------------
   A Z80 re-implementation of PuzzleScript's compiled-rule semantics
   (bitmask cell model), fed by a data blob appended to this 32 KB base ROM
   by PuzzleScript's SMS exporter (src/js/sms_exporter.js).

   Mirrors, faithfully, the reference implementation in src/js/engine.js:
     - cells are 32-bit object masks (<= 32 objects, STRIDE_OBJ == 1)
     - movements are 5 bits per collision layer (<= 6 layers, STRIDE_MOV == 1)
     - CellPattern  { objectsPresent/Missing, anyObjectsPresent[],
                      movementsPresent/Missing }
     - CellReplacement { objectsClear/Set, movementsClear|LayerMask,
                      movementsSet, randomEntityMask, randomDirMask }
     - rule groups loop to fixpoint (cap 200), startloop/endloop loopPoints,
       late rules, cancel/restart/win/again/checkpoint/message commands,
       win conditions with aggregate flags.

   Objects are rendered as 16x16 tiles (2x2 hardware tiles), composited
   bottom-to-top by collision layer with per-pixel transparency masks and
   cached in VRAM per unique cell mask.

   Build: SDCC 4.x + devkitSMS.  PC_TEST builds a native test harness.
   ============================================================================ */

#ifndef PC_TEST
#include "lib/SMSlib.h"
#else
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#endif

#include "font.h"

typedef unsigned char  u8;
typedef unsigned short u16;
typedef unsigned long  u32;
typedef signed char    s8;

/* ---------------------------------------------------------------- limits -- */
#define MAX_OBJECTS   32
#define MAX_LAYERS    6
#define MAX_W         16
#define MAX_H         12
#define MAX_CELLS     (MAX_W * MAX_H)
#define MAX_ROWS      6          /* cell rows per rule                        */
#define UNDO_DEPTH    3
#define MAX_COMBOS    87         /* (352 - 4) / 4 VRAM tile quads             */
#define COMBO_BASE    1          /* tile 0 is blank                           */
#define FONT_BASE     352        /* 96 glyphs: 352..447                       */
#define GAME_BANK     2          /* first 16 KB page after the 32 KB base     */

/* command bits (match sms_exporter.js) */
#define CMD_CANCEL     0x01
#define CMD_RESTART    0x02
#define CMD_WIN        0x04
#define CMD_AGAIN      0x08
#define CMD_CHECKPOINT 0x10
#define CMD_MESSAGE    0x20

/* header flag bits */
#define FLG_RUNRULESONSTART 0x01
#define FLG_NOUNDO          0x02
#define FLG_NORESTART       0x04
#define FLG_REQPLAYERMOVE   0x08
#define FLG_NOACTION        0x10

/* ---------------------------------------------------------- data blob I/O -- */
#ifdef PC_TEST
static u8 *pc_blob; static long pc_blob_len;
static u8 *map_bank(u8 rel_bank) { return pc_blob + (long)rel_bank * 16384; }
#else
static u8 *map_bank(u8 rel_bank) {
    SMS_mapROMBank(GAME_BANK + rel_bank);
    return (u8 *)0x8000;
}
#endif

static u8  rd8 (const u8 *p) { return p[0]; }
static u16 rd16(const u8 *p) { return (u16)p[0] | ((u16)p[1] << 8); }
static u32 rd32(const u8 *p) {
    return (u32)p[0] | ((u32)p[1] << 8) | ((u32)p[2] << 16) | ((u32)p[3] << 24);
}

/* far pointer = u8 bank, u16 offset-within-bank */
static u8 *far_resolve(const u8 *p3) { return map_bank(p3[0]) + rd16(p3 + 1); }

/* ------------------------------------------------------ header (RAM copy) -- */
/* offsets in the header record */
#define H_MAGIC      0
#define H_VERSION    4
#define H_NOBJ       5
#define H_NLAYERS    6
#define H_NLEVELS    7
#define H_PLAYERMASK 8
#define H_FLAGS      12
#define H_AGAIN      13
#define H_TEXTCOL    14
#define H_LAYERMASKS 16
#define H_OBJLAYER   40
#define H_DRAWORDER  72
#define H_PALETTE    104
#define H_TILES      120
#define H_LEVELS     123
#define H_RULES      126
#define H_LATERULES  129
#define H_WIN        132
#define H_MESSAGES   135
#define H_TITLE      138
#define H_AUTHOR     170
#define H_SIZE       202

static u8  g_nobj, g_nlayers, g_nlevels, g_flags, g_again_interval, g_textcol;
static u32 g_playerMask, g_allMask;
static u32 g_layerMasks[MAX_LAYERS];
static u8  g_objLayer[MAX_OBJECTS];
static u8  g_drawOrder[MAX_OBJECTS];
static u8  g_palette[16];
static u8  g_far_tiles[3], g_far_levels[3], g_far_rules[3],
           g_far_late[3], g_far_win[3], g_far_msgs[3];
static char g_title[32], g_author[32];

/* --------------------------------------------------------------- level RAM -- */
static u32 lev[MAX_CELLS];          /* object masks                            */
static u32 mov[MAX_CELLS];          /* movement masks (5 bits per layer)       */
static u32 bak[MAX_CELLS];          /* pre-turn backup (cancel / dirty check)  */
static u32 chkpt[MAX_CELLS];        /* restart target                          */
static u32 undo_buf[UNDO_DEPTH][MAX_CELLS];
static u8  undo_count, undo_head;

static u8 g_w, g_h;                 /* current level size                      */
static u8 g_ncells;
static u8 g_level_idx;

static u8  turn_cmd;                /* CMD_* accumulated during a turn         */
static u8  turn_msg;                /* message index, 0xFF = none              */
static u8  pre_player[24];          /* bitset: cells holding player pre-turn   */

/* ------------------------------------------------------------------- RNG -- */
static u16 rng_state = 0xACE1;
static u8 rng4(void) {              /* 2 random bits                           */
    u16 s = rng_state;
    s ^= s << 7; s ^= s >> 9; s ^= s << 8;
    rng_state = s;
    return (u8)(s & 3);
}
static u8 rng_mod(u8 n) {
    u16 s = rng_state;
    s ^= s << 7; s ^= s >> 9; s ^= s << 8;
    rng_state = s;
    return (u8)(s % n);
}

/* ================================================================ RULES ==== */
/*
   rules blob:
     u8  groupCount
     u8  loopPoint[groupCount+1]         0xFF = none
     u16 groupOffset[groupCount]         relative to blob start
   group:
     u8  ruleCount
     rules...
   rule:
     u16 byteLen (of whole rule record incl. this field)
     u8  direction (1 up, 2 down, 4 left, 8 right)
     u8  flags (bit0 hasReplacements)
     u8  cmdMask
     u8  msgIdx
     u8  rowCount
     rows: u8 cellCount, cells...
   cell:
     u32 objP, u32 objM, u32 movP, u32 movM
     u8  anyCount, anyCount * u32
     u8  hasRepl
     if hasRepl: u32 objClear, objSet, movClear (pre-ORed with layerMask),
                 movSet, randEnt, randDir
*/

static s8  rule_dx, rule_dy;
static int rule_d;                       /* cell index delta for direction     */
static u8  rule_rowCount, rule_hasRepl;
static const u8 *rule_rows[MAX_ROWS];    /* -> u8 cellCount, cells...          */
static u8  rule_rowLen[MAX_ROWS];
static u8  rule_pos[MAX_ROWS];           /* matched start cell per row         */
static u8  rule_matched, rule_changed;

/* skip over one serialized cell, return pointer past it */
static const u8 *cell_skip(const u8 *p) {
    u8 anyc, hasRepl;
    p += 16;
    anyc = *p++;
    p += (u16)anyc << 2;
    hasRepl = *p++;
    if (hasRepl) p += 24;
    return p;
}

/* does the cell pattern at p match board cell i ? */
static u8 cell_matches(const u8 *p, u8 i) {
    u32 c = lev[i], m = mov[i], v;
    u8 anyc;
    v = rd32(p);      if ((c & v) != v) return 0;   /* objectsPresent (all)   */
    v = rd32(p + 4);  if (c & v)        return 0;   /* objectsMissing         */
    v = rd32(p + 8);  if ((m & v) != v) return 0;   /* movementsPresent       */
    v = rd32(p + 12); if (m & v)        return 0;   /* movementsMissing       */
    p += 16;
    anyc = *p++;
    while (anyc--) {
        v = rd32(p); p += 4;
        if (!(c & v)) return 0;                     /* anyObjectsPresent      */
    }
    return 1;
}

/* apply the replacement (if any) of the cell at p to board cell i.
   returns 1 if the board changed.  Mirrors generateReplaceFunction().        */
static u8 cell_apply(const u8 *p, u8 i) {
    u32 objClear, objSet, movClear, movSet, randEnt, randDir;
    u32 nc, nm;
    u8 anyc, hasRepl, k;
    p += 16; anyc = *p++; p += (u16)anyc << 2;
    hasRepl = *p++;
    if (!hasRepl) return 0;
    objClear = rd32(p);      objSet  = rd32(p + 4);
    movClear = rd32(p + 8);  movSet  = rd32(p + 12);
    randEnt  = rd32(p + 16); randDir = rd32(p + 20);

    if (randEnt) {                       /* random object from a property     */
        u8 choices[MAX_OBJECTS], n = 0, r, lay;
        for (k = 0; k < g_nobj; k++)
            if (randEnt & ((u32)1 << k)) choices[n++] = k;
        r = choices[rng_mod(n)];
        lay = g_objLayer[r];
        objSet   |= (u32)1 << r;
        objClear |= g_layerMasks[lay];
        movClear |= (u32)0x1F << (lay + (lay << 2));  /* 5*lay */
    }
    if (randDir) {                       /* "randomdir" per layer             */
        u8 sh = 0;
        for (k = 0; k < g_nlayers; k++, sh += 5)
            if (randDir & ((u32)1 << sh))
                movSet |= (u32)1 << (rng4() + sh);
    }

    nc = (lev[i] & ~objClear) | objSet;
    nm = (mov[i] & ~movClear) | movSet;
    if (nc == lev[i] && nm == mov[i]) return 0;
    lev[i] = nc; mov[i] = nm;
    return 1;
}

/* does the whole cell row r match starting at cell i ? */
static u8 row_matches_at(u8 r, u8 i) {
    const u8 *p = rule_rows[r] + 1;
    u8 k, n = rule_rowLen[r];
    int idx = i;
    for (k = 0; k < n; k++) {
        if (!cell_matches(p, (u8)idx)) return 0;
        p = cell_skip(p);
        idx += rule_d;
    }
    return 1;
}

static void row_apply_at(u8 r, u8 i) {
    const u8 *p = rule_rows[r] + 1;
    u8 k, n = rule_rowLen[r];
    int idx = i;
    for (k = 0; k < n; k++) {
        if (cell_apply(p, (u8)idx)) rule_changed = 1;
        p = cell_skip(p);
        idx += rule_d;
    }
}

/* enumerate the candidate start positions of row r (bounds by direction),
   recursing across rows to form tuples; apply at complete tuples.            */
static void scan_row(u8 r) {
    u8 n = rule_rowLen[r];
    u8 x0 = 0, y0 = 0, x1 = g_w, y1 = g_h;   /* exclusive bounds              */
    u8 x, y, i, k;

    if (rule_dx > 0) { x1 = g_w - n + 1; }
    else if (rule_dx < 0) { x0 = n - 1; }
    else if (rule_dy > 0) { y1 = g_h - n + 1; }
    else { y0 = n - 1; }
    if (x1 > g_w || y1 > g_h) return;        /* row longer than board         */

    for (x = x0; x < x1; x++) {
        i = (u8)(x * g_h + y0);
        for (y = y0; y < y1; y++, i++) {
            if (!row_matches_at(r, i)) continue;
            rule_pos[r] = i;
            if (r + 1 < rule_rowCount) {
                scan_row(r + 1);
                if (rule_matched && !rule_hasRepl) return;
            } else {
                rule_matched = 1;
                if (!rule_hasRepl) return;
                /* recheck the full tuple (earlier applications may have
                   invalidated outer rows), then apply */
                for (k = 0; k < rule_rowCount; k++)
                    if (!row_matches_at(k, rule_pos[k])) break;
                if (k == rule_rowCount)
                    for (k = 0; k < rule_rowCount; k++)
                        row_apply_at(k, rule_pos[k]);
            }
        }
    }
}

/* try to apply one rule; returns 1 if the board changed (tryApply()).        */
static u8 rule_try_apply(const u8 *p) {
    u8 dir, cmd, msg, r;
    const u8 *q;
    p += 2;                                  /* byteLen                       */
    dir = *p++;
    rule_hasRepl = *p++ & 1;
    cmd = *p++;
    msg = *p++;
    rule_rowCount = *p++;

    rule_dx = 0; rule_dy = 0;
    switch (dir) {
        case 1: rule_dy = -1; break;
        case 2: rule_dy =  1; break;
        case 4: rule_dx = -1; break;
        default: rule_dx = 1; break;
    }
    rule_d = (int)rule_dx * g_h + rule_dy;

    for (r = 0; r < rule_rowCount; r++) {
        rule_rows[r] = p;
        rule_rowLen[r] = *p;
        q = p + 1;
        { u8 k; for (k = 0; k < rule_rowLen[r]; k++) q = cell_skip(q); }
        p = q;
    }

    rule_matched = 0; rule_changed = 0;
    scan_row(0);
    if (rule_matched) {                      /* commands queue on match       */
        turn_cmd |= cmd;
        if ((cmd & CMD_MESSAGE) && turn_msg == 0xFF) turn_msg = msg;
    }
    return rule_changed;
}

/* apply one rule group to fixpoint; returns 1 if anything changed            */
static u8 apply_rule_group(const u8 *gp) {
    u8 ruleCount = *gp, hasChanges = 0, made = 1;
    u8 loopcount = 0;
    while (made && ++loopcount < 200) {
        const u8 *p = gp + 1;
        u8 ri, consecFail = 0;
        made = 0;
        for (ri = 0; ri < ruleCount; ri++) {
            if (rule_try_apply(p)) { made = 1; consecFail = 0; }
            else if (++consecFail == ruleCount) break;
            p += rd16(p);
        }
        if (made) hasChanges = 1;
    }
    return hasChanges;
}

/* applyRules(): run all groups with startloop/endloop loop-points            */
static void apply_rules(const u8 *far3) {
    const u8 *blob = far_resolve(far3);
    u8 groupCount = blob[0];
    const u8 *loopPt  = blob + 1;
    const u8 *offsets = blob + 1 + groupCount + 1;
    u8 gi = 0, loopProp = 0, loopCount = 0;

    if (!groupCount) return;
    while (gi < groupCount) {
        if (apply_rule_group(blob + rd16(offsets + ((u16)gi << 1))))
            loopProp = 1;
        if (loopProp && loopPt[gi] != 0xFF) {
            gi = loopPt[gi]; loopProp = 0;
            if (++loopCount > 200) break;
            continue;
        }
        gi++;
        if (gi == groupCount && loopProp && loopPt[gi] != 0xFF) {
            gi = loopPt[gi]; loopProp = 0;
            if (++loopCount > 200) break;
        }
    }
}

/* ========================================================== MOVEMENT ====== */
/* repositionEntitiesOnLayer() — returns 1 when the movement bit is consumed  */
static u8 reposition(u8 i, u8 x, u8 y, u8 layer, u8 lm) {
    s8 dx = 0, dy = 0;
    u8 ti;
    u32 lmask, moving;

    switch (lm) {
        case 1: dy = -1; break;
        case 2: dy =  1; break;
        case 4: dx = -1; break;
        case 8: dx =  1; break;
        default: break;                     /* action (16), '?', combos       */
    }
    if ((dx | dy) == 0) {
        if (lm == 16) return 1;             /* action consumed, no motion     */
        return 0;                           /* '?' / weird masks: JS parity   */
    }
    if ((x == 0 && dx < 0) || (x == g_w - 1 && dx > 0) ||
        (y == 0 && dy < 0) || (y == g_h - 1 && dy > 0)) return 0;

    ti = (u8)((int)i + (int)dx * g_h + dy);
    lmask = g_layerMasks[layer];
    if (lev[ti] & lmask) return 0;          /* layer collision                */
    moving = lev[i] & lmask;
    lev[i] &= ~lmask;
    lev[ti] |= moving;
    return 1;
}

/* resolveMovements(): sweep until nothing else can move, then clear          */
static void resolve_movements(void) {
    u8 moved = 1;
    while (moved) {
        u8 x, y, i = 0, layer, sh;
        moved = 0;
        for (x = 0; x < g_w; x++)
            for (y = 0; y < g_h; y++, i++) {
                u32 m = mov[i];
                if (!m) continue;
                for (layer = 0, sh = 0; layer < g_nlayers; layer++, sh += 5) {
                    u8 lm = (u8)((m >> sh) & 0x1F);
                    if (!lm) continue;
                    if (reposition(i, x, y, layer, lm)) {
                        m &= ~((u32)0x1F << sh);
                        moved = 1;
                    }
                }
                mov[i] = m;
            }
    }
    { u8 i; for (i = 0; i < g_ncells; i++) mov[i] = 0; }
}

/* ======================================================= WIN CONDITIONS === */
static u8 check_win(void) {
    const u8 *p = far_resolve(g_far_win);
    u8 n = *p++, w;
    if (turn_cmd & CMD_WIN) return 1;
    if (!n) return 0;
    for (w = 0; w < n; w++, p += 10) {
        u8 type = p[0], aggr = p[1], i, hit = 0;
        u32 f1 = rd32(p + 2), f2 = rd32(p + 6);
        for (i = 0; i < g_ncells; i++) {
            u32 c = lev[i];
            u8 m1 = (aggr & 1) ? ((c & f1) == f1) : ((c & f1) != 0);
            u8 m2 = (aggr & 2) ? ((c & f2) == f2) : ((c & f2) != 0);
            if (type == 2) { if (m1 && !m2) return 0; }        /* ALL  */
            else if (m1 && m2) { hit = 1; if (type == 0) return 0; else break; }
        }
        if (type == 1 && !hit) return 0;                       /* SOME */
    }
    return 1;
}

/* ============================================================== TURN ====== */
static void player_bitset_record(void) {
    u8 i;
    for (i = 0; i < 24; i++) pre_player[i] = 0;
    for (i = 0; i < g_ncells; i++)
        if (lev[i] & g_playerMask) pre_player[i >> 3] |= 1 << (i & 7);
}

/* processInput(dir): dir 0 up,1 left,2 down,3 right,4 action, -1 none.
   Returns 1 if the board was modified.  Command handling is the caller's.   */
static u8 turn(s8 dir) {
    u8 i, modified = 0;
    static const u8 dirmask_tab[5] = { 1, 4, 2, 8, 16 };

    for (i = 0; i < g_ncells; i++) { bak[i] = lev[i]; mov[i] = 0; }
    turn_cmd = 0; turn_msg = 0xFF;

    if (dir >= 0) {
        u32 dm = dirmask_tab[(u8)dir];
        u8 layer, sh;
        player_bitset_record();
        for (i = 0; i < g_ncells; i++) {
            if (!(lev[i] & g_playerMask)) continue;
            for (layer = 0, sh = 0; layer < g_nlayers; layer++, sh += 5)
                if (lev[i] & g_playerMask & g_layerMasks[layer])
                    mov[i] |= dm << sh;
        }
    }

    apply_rules(g_far_rules);
    resolve_movements();
    apply_rules(g_far_late);

    /* require_player_movement */
    if (dir >= 0 && dir <= 3 && (g_flags & FLG_REQPLAYERMOVE)) {
        u8 somemoved = 0;
        for (i = 0; i < g_ncells; i++)
            if ((pre_player[i >> 3] & (1 << (i & 7))) &&
                !(lev[i] & g_playerMask)) { somemoved = 1; break; }
        if (!somemoved) turn_cmd |= CMD_CANCEL;
    }

    if (turn_cmd & CMD_CANCEL) {
        for (i = 0; i < g_ncells; i++) { lev[i] = bak[i]; mov[i] = 0; }
        return 0;
    }
    for (i = 0; i < g_ncells; i++)
        if (lev[i] != bak[i]) { modified = 1; break; }
    if ((turn_cmd & CMD_CHECKPOINT) && modified)
        for (i = 0; i < g_ncells; i++) chkpt[i] = lev[i];
    return modified;
}

/* -------------------------------------------------------------- undo ring -- */
static void undo_push(const u32 *snapshot) {
    u8 i;
    if (g_flags & FLG_NOUNDO) return;
    for (i = 0; i < g_ncells; i++) undo_buf[undo_head][i] = snapshot[i];
    undo_head = (undo_head + 1) % UNDO_DEPTH;
    if (undo_count < UNDO_DEPTH) undo_count++;
}
static u8 undo_pop(void) {
    u8 i;
    if (!undo_count) return 0;
    undo_head = (undo_head + UNDO_DEPTH - 1) % UNDO_DEPTH;
    undo_count--;
    for (i = 0; i < g_ncells; i++) { lev[i] = undo_buf[undo_head][i]; mov[i] = 0; }
    return 1;
}

/* ============================================================ LEVEL LOAD == */
/* returns level type: 0 = playable, 1 = message; message text -> msg_ptr    */
static const u8 *msg_ptr;
static u8 level_fetch(u8 idx) {
    const u8 *ix = far_resolve(g_far_levels);
    const u8 *e = ix + 1 + ((u16)idx << 2);       /* u8 count, 4-byte entries */
    u8 type = e[0];
    const u8 *p = far_resolve(e + 1);
    if (type == 1) { msg_ptr = p; return 1; }
    g_w = p[0]; g_h = p[1];
    g_ncells = (u8)(g_w * g_h);
    {
        u8 i; const u8 *c = p + 2;
        for (i = 0; i < g_ncells; i++, c += 4) {
            lev[i] = rd32(c);
            chkpt[i] = lev[i];
            mov[i] = 0;
        }
    }
    undo_count = 0; undo_head = 0;
    return 0;
}

/* ============================================================ RENDERING === */
#ifndef PC_TEST

static u32 combo_key[MAX_COMBOS];
static u8  combo_count;
static u8  cell_combo[MAX_CELLS];   /* what each board cell currently shows:
                                       combo idx, 0xFE = blank, 0xFF = dirty */
static u8  off_x, off_y;            /* tilemap offset centering the board     */
static u8  compose_buf[128];        /* 4 subtiles, 4bpp planar                */

/* composite every object present in `key` (bottom-to-top by layer order)
   into compose_buf, honoring per-pixel transparency masks.
   tile data per object: 4 subtiles x 8 rows x [mask,p0,p1,p2,p3] = 160 B     */
static void compose(u32 key) {
    const u8 *tiles = far_resolve(g_far_tiles);
    u8 o, st, row;
    for (row = 0; row < 128; row++) compose_buf[row] = 0;
    for (o = 0; o < g_nobj; o++) {
        u8 obj = g_drawOrder[o];
        const u8 *src;
        u8 *dst;
        if (!(key & ((u32)1 << obj))) continue;
        src = tiles + ((u16)obj * 160);
        dst = compose_buf;
        for (st = 0; st < 4; st++)
            for (row = 0; row < 8; row++) {
                u8 m = src[0], nm = (u8)~m;
                dst[0] = (dst[0] & nm) | (src[1] & m);
                dst[1] = (dst[1] & nm) | (src[2] & m);
                dst[2] = (dst[2] & nm) | (src[3] & m);
                dst[3] = (dst[3] & nm) | (src[4] & m);
                src += 5; dst += 4;
            }
    }
}

static u8 combo_get(u32 key) {          /* returns combo idx or 0xFE          */
    u8 i;
    for (i = 0; i < combo_count; i++)
        if (combo_key[i] == key) return i;
    if (combo_count >= MAX_COMBOS) {
        /* cache full: fall back to the topmost single object of the cell     */
        s8 o;
        for (o = (s8)g_nobj - 1; o >= 0; o--) {
            u32 single = (u32)1 << g_drawOrder[(u8)o];
            if (key & single) {
                if (key == single) return 0xFE;   /* even singles overflow    */
                return combo_get(single);
            }
        }
        return 0xFE;
    }
    compose(key);
    SMS_loadTiles(compose_buf, COMBO_BASE + ((u16)combo_count << 2), 128);
    combo_key[combo_count] = key;
    return combo_count++;
}

static void draw_cell(u8 i, u8 x, u8 y) {
    u32 key = lev[i] & g_allMask;
    u8 ci = key ? combo_get(key) : 0xFE;
    u16 base;
    u8 tx, ty;
    if (cell_combo[i] == ci) return;
    cell_combo[i] = ci;
    tx = off_x + (x << 1); ty = off_y + (y << 1);
    if (ci == 0xFE) {
        SMS_setTileatXY(tx,     ty,     0);
        SMS_setTileatXY(tx + 1, ty,     0);
        SMS_setTileatXY(tx,     ty + 1, 0);
        SMS_setTileatXY(tx + 1, ty + 1, 0);
        return;
    }
    base = COMBO_BASE + ((u16)ci << 2);
    SMS_setTileatXY(tx,     ty,     base);
    SMS_setTileatXY(tx + 1, ty,     base + 1);
    SMS_setTileatXY(tx,     ty + 1, base + 2);
    SMS_setTileatXY(tx + 1, ty + 1, base + 3);
}

static void draw_board(void) {          /* draws only stale cells             */
    u8 x, y, i = 0;
    for (x = 0; x < g_w; x++)
        for (y = 0; y < g_h; y++, i++)
            draw_cell(i, x, y);
}

static void screen_clear(void) {
    u8 x, y;
    for (y = 0; y < 24; y++) {
        SMS_setNextTileatXY(0, y);
        for (x = 0; x < 32; x++) SMS_setTile(0);
    }
}

static void board_reset_view(void) {
    u8 i;
    screen_clear();
    combo_count = 0;
    for (i = 0; i < g_ncells; i++) cell_combo[i] = 0xFF;
    off_x = (u8)((32 - (g_w << 1)) >> 1);
    off_y = (u8)((24 - (g_h << 1)) >> 1);
    draw_board();
}

/* ------------------------------------------------------------------ text -- */
static void draw_text(u8 x, u8 y, const char *s) {
    SMS_setNextTileatXY(x, y);
    while (*s) {
        u8 c = (u8)*s++;
        if (c < 32 || c > 127) c = '?';
        SMS_setTile(FONT_BASE + c - 32);
    }
}
static u8 str_len(const char *s) { u8 n = 0; while (s[n]) n++; return n; }
static void draw_text_centered(u8 y, const char *s) {
    u8 n = str_len(s);
    if (n > 32) n = 32;
    draw_text((u8)((32 - n) >> 1), y, s);
}

/* word-wrapped message screen; waits for button 1                            */
static void wait_button1(void);
static void show_message(const u8 *text) {
    char line[31];
    u8 y = 8;
    screen_clear();
    while (*text && y < 20) {
        u8 n = 0, last_sp = 0xFF;
        while (text[n] && n < 30) {
            if (text[n] == ' ') last_sp = n;
            n++;
        }
        if (text[n] && last_sp != 0xFF && n >= 30) n = last_sp;
        { u8 k; for (k = 0; k < n; k++) line[k] = (char)text[k]; line[n] = 0; }
        draw_text_centered(y, line);
        y += 2;
        text += n;
        while (*text == ' ') text++;
    }
    draw_text_centered(21, "PRESS 1");
    wait_button1();
}

/* ------------------------------------------------------------- input ----- */
static u8 frame_count;
static void frame_wait(void) { SMS_waitForVBlank(); frame_count++; }

static void wait_button1(void) {
    for (;;) {
        frame_wait();
        if (SMS_getKeysPressed() & PORT_A_KEY_1) return;
    }
}

#define REPEAT_DELAY 18
#define REPEAT_RATE  7

/* returns 0..4 = up,left,down,right,action; 5 = undo; 6 = restart; 0xFF none */
static u8 poll_input(void) {
    static u16 held_prev; static u8 rep_timer; static u8 hold2;
    u16 ks = SMS_getKeysStatus();
    u16 pressed = ks & ~held_prev;
    u8 r = 0xFF;

    if (ks & PORT_A_KEY_2) {
        hold2++;
        if (hold2 == 60 && !(g_flags & FLG_NORESTART)) { held_prev = ks; return 6; }
    } else {
        if (hold2 && hold2 < 60) { held_prev = ks; hold2 = 0; return 5; }
        hold2 = 0;
    }

    if (pressed & PORT_A_KEY_UP) r = 0;
    else if (pressed & PORT_A_KEY_LEFT) r = 1;
    else if (pressed & PORT_A_KEY_DOWN) r = 2;
    else if (pressed & PORT_A_KEY_RIGHT) r = 3;
    else if ((pressed & PORT_A_KEY_1) && !(g_flags & FLG_NOACTION)) r = 4;

    if (r != 0xFF) rep_timer = REPEAT_DELAY;
    else if (ks & (PORT_A_KEY_UP | PORT_A_KEY_DOWN | PORT_A_KEY_LEFT | PORT_A_KEY_RIGHT)) {
        if (rep_timer) rep_timer--;
        else {
            rep_timer = REPEAT_RATE;
            if (ks & PORT_A_KEY_UP) r = 0;
            else if (ks & PORT_A_KEY_LEFT) r = 1;
            else if (ks & PORT_A_KEY_DOWN) r = 2;
            else if (ks & PORT_A_KEY_RIGHT) r = 3;
        }
    }
    held_prev = ks;
    rng_state ^= frame_count;             /* stir RNG with input timing       */
    return r;
}

/* -------------------------------------------------------------- sequences -- */
static void win_flash(void) {
    u8 f, i;
    for (f = 0; f < 3; f++) {
        for (i = 0; i < 16; i++) SMS_setBGPaletteColor(i, 0x3F);
        frame_wait(); frame_wait(); frame_wait();
        SMS_loadBGPalette(g_palette);
        frame_wait(); frame_wait(); frame_wait();
    }
}

static void title_screen(void) {
    screen_clear();
    draw_text_centered(8, g_title);
    if (g_author[0]) {
        draw_text_centered(11, "BY");
        draw_text_centered(12, g_author);
    }
    draw_text_centered(17, "PRESS 1 TO START");
    draw_text_centered(20, "2:UNDO  HOLD 2:RESTART");
    wait_button1();
}

/* handle post-turn commands + win. returns 1 when the level was completed.   */
static u8 post_turn(u8 modified) {
    if (turn_cmd & CMD_RESTART) {
        u8 i;
        undo_push(bak);
        for (i = 0; i < g_ncells; i++) { lev[i] = chkpt[i]; mov[i] = 0; }
        draw_board();
        return 0;
    }
    if (modified) undo_push(bak);
    draw_board();

    if (turn_msg != 0xFF) {
        const u8 *mi = far_resolve(g_far_msgs);
        const u8 *mp = far_resolve(mi + 1 + ((u16)turn_msg * 3));
        u8 i;
        show_message(mp);
        board_reset_view();
        for (i = 0; i < 60; i++) frame_wait();
    }

    if (check_win()) { win_flash(); return 1; }

    /* AGAIN loop */
    if ((turn_cmd & CMD_AGAIN) && modified) {
        u8 iter = 0;
        while (iter++ < 250) {
            u8 f, m;
            for (f = 0; f < g_again_interval; f++) frame_wait();
            m = turn(-1);
            draw_board();
            if (turn_cmd & CMD_RESTART) return post_turn(m);
            if (check_win()) { win_flash(); return 1; }
            if (!((turn_cmd & CMD_AGAIN) && m)) break;
        }
    }
    return 0;
}

static void load_header(void) {
    const u8 *h = map_bank(0);
    u8 i;
    g_nobj  = h[H_NOBJ];  g_nlayers = h[H_NLAYERS];
    g_nlevels = h[H_NLEVELS];
    g_playerMask = rd32(h + H_PLAYERMASK);
    g_flags = h[H_FLAGS]; g_again_interval = h[H_AGAIN];
    g_textcol = h[H_TEXTCOL];
    for (i = 0; i < MAX_LAYERS; i++) g_layerMasks[i] = rd32(h + H_LAYERMASKS + (i << 2));
    for (i = 0; i < MAX_OBJECTS; i++) {
        g_objLayer[i]  = h[H_OBJLAYER + i];
        g_drawOrder[i] = h[H_DRAWORDER + i];
    }
    for (i = 0; i < 16; i++) g_palette[i] = h[H_PALETTE + i];
    for (i = 0; i < 3; i++) {
        g_far_tiles[i]  = h[H_TILES + i];
        g_far_levels[i] = h[H_LEVELS + i];
        g_far_rules[i]  = h[H_RULES + i];
        g_far_late[i]   = h[H_LATERULES + i];
        g_far_win[i]    = h[H_WIN + i];
        g_far_msgs[i]   = h[H_MESSAGES + i];
    }
    for (i = 0; i < 32; i++) { g_title[i] = (char)h[H_TITLE + i]; g_author[i] = (char)h[H_AUTHOR + i]; }
    g_title[31] = 0; g_author[31] = 0;
    g_allMask = (g_nobj >= 32) ? 0xFFFFFFFFUL : (((u32)1 << g_nobj) - 1);
}

void main(void) {
    SMS_displayOff();
    load_header();
    SMS_loadBGPalette(g_palette);
    SMS_loadSpritePalette(g_palette);
    SMS_setBackdropColor(0);
    SMS_load1bppTiles(ps_font, FONT_BASE, 768, 0, g_textcol);
    SMS_initSprites(); SMS_copySpritestoSAT();
    screen_clear();
    SMS_displayOn();

    for (;;) {
        title_screen();
        g_level_idx = 0;
        while (g_level_idx < g_nlevels) {
            if (level_fetch(g_level_idx)) {           /* message "level"     */
                show_message(msg_ptr);
                g_level_idx++;
                continue;
            }
            board_reset_view();
            if (g_flags & FLG_RUNRULESONSTART) { turn(-1); draw_board(); }

            for (;;) {
                u8 in;
                frame_wait();
                in = poll_input();
                if (in == 0xFF) continue;
                if (in == 5) { if (undo_pop()) draw_board(); continue; }
                if (in == 6) {
                    u8 i;
                    undo_push(lev);
                    for (i = 0; i < g_ncells; i++) { lev[i] = chkpt[i]; mov[i] = 0; }
                    draw_board();
                    continue;
                }
                if (post_turn(turn((s8)in))) break;   /* level complete       */
            }
            g_level_idx++;
        }
        screen_clear();
        draw_text_centered(11, "CONGRATULATIONS!");
        draw_text_centered(14, "YOU WIN");
        wait_button1();
    }
}

SMS_EMBED_SEGA_ROM_HEADER(9999, 0);

#else /* ======================================================== PC_TEST === */

static const char obj_letter(u8 o) {
    return (o < 26) ? ('A' + o) : ('a' + o - 26);
}

static void print_board(void) {
    u8 x, y;
    for (y = 0; y < g_h; y++) {
        for (x = 0; x < g_w; x++) {
            u32 c = lev[x * g_h + y] & g_allMask;
            char ch = '.';
            s8 o;
            for (o = (s8)g_nobj - 1; o >= 0; o--) {
                u8 obj = g_drawOrder[(u8)o];
                if (c & ((u32)1 << obj)) { ch = obj_letter(obj); break; }
            }
            putchar(ch);
        }
        putchar('\n');
    }
}

static void load_header_pc(void) {
    const u8 *h = map_bank(0);
    u8 i;
    if (memcmp(h, "PSMS", 4)) { fprintf(stderr, "bad magic\n"); exit(1); }
    g_nobj = h[H_NOBJ]; g_nlayers = h[H_NLAYERS]; g_nlevels = h[H_NLEVELS];
    g_playerMask = rd32(h + H_PLAYERMASK);
    g_flags = h[H_FLAGS]; g_again_interval = h[H_AGAIN];
    for (i = 0; i < MAX_LAYERS; i++) g_layerMasks[i] = rd32(h + H_LAYERMASKS + (i << 2));
    for (i = 0; i < MAX_OBJECTS; i++) {
        g_objLayer[i] = h[H_OBJLAYER + i];
        g_drawOrder[i] = h[H_DRAWORDER + i];
    }
    for (i = 0; i < 3; i++) {
        g_far_tiles[i] = h[H_TILES + i];  g_far_levels[i] = h[H_LEVELS + i];
        g_far_rules[i] = h[H_RULES + i];  g_far_late[i] = h[H_LATERULES + i];
        g_far_win[i] = h[H_WIN + i];      g_far_msgs[i] = h[H_MESSAGES + i];
    }
    g_allMask = (g_nobj >= 32) ? 0xFFFFFFFFUL : (((u32)1 << g_nobj) - 1);
    printf("PSMS blob: %u objects, %u layers, %u levels, playerMask=%08lX\n",
           g_nobj, g_nlayers, g_nlevels, (unsigned long)g_playerMask);
}

/* usage: ps_test <blob> <level#> <moves e.g. "ULDRXZ." X=action Z=undo>      */
int main(int argc, char **argv) {
    FILE *f;
    const char *moves;
    u8 lvl;
    if (argc < 4) { fprintf(stderr, "usage: %s blob level moves\n", argv[0]); return 1; }
    f = fopen(argv[1], "rb");
    if (!f) { perror("blob"); return 1; }
    fseek(f, 0, SEEK_END); pc_blob_len = ftell(f); fseek(f, 0, SEEK_SET);
    pc_blob = malloc(pc_blob_len);
    fread(pc_blob, 1, pc_blob_len, f);
    fclose(f);

    load_header_pc();
    lvl = (u8)atoi(argv[2]);
    if (level_fetch(lvl)) { printf("MESSAGE: %s\n", (const char *)msg_ptr); return 0; }
    printf("level %u: %ux%u\n", lvl, g_w, g_h);
    if (g_flags & FLG_RUNRULESONSTART) turn(-1);
    print_board();

    for (moves = argv[3]; *moves; moves++) {
        s8 d = -2;
        u8 m;
        switch (*moves) {
            case 'U': d = 0; break; case 'L': d = 1; break;
            case 'D': d = 2; break; case 'R': d = 3; break;
            case 'X': d = 4; break; case '.': d = -1; break;
            case 'Z': undo_pop(); printf("-- undo --\n"); print_board(); continue;
        }
        if (d == -2) continue;
        m = turn(d);
        if (turn_cmd & CMD_RESTART) {
            u8 i;
            undo_push(bak);
            for (i = 0; i < g_ncells; i++) { lev[i] = chkpt[i]; mov[i] = 0; }
            printf("-- restart command --\n");
        } else if (m) {
            undo_push(bak);
        }
        /* again loop */
        if ((turn_cmd & CMD_AGAIN) && m) {
            u8 iter = 0;
            while (iter++ < 250) {
                u8 m2 = turn(-1);
                if (!((turn_cmd & CMD_AGAIN) && m2)) break;
            }
        }
        printf("-- move %c (modified=%u cmd=%02X) --\n", *moves, m, turn_cmd);
        print_board();
        if (check_win()) { printf("*** WIN ***\n"); return 0; }
    }
    printf("(no win)\n");
    return 0;
}
#endif /* PC_TEST */
