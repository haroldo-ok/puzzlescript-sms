/* ============================================================================
   PuzzleScript SMS engine  --  base ROM
   ----------------------------------------------------------------------------
   A Z80 re-implementation of the PuzzleScript turn pipeline, driven entirely
   by data appended to this 32 KB ROM (banks 2+, mapped at 0x8000 via the
   standard Sega mapper).  The JS exporter (src/js/exportsms.js) serialises
   the *compiled* PuzzleScript state (bitmask cell patterns / replacements)
   into the format documented below, so the semantics here mirror engine.js:

     - cells are 32-bit object bitmasks              (<= 32 objects)
     - movements are 5 bits per collision layer      (<= 6 layers)
     - CellPattern:      objectsPresent / objectsMissing / anyObjectsPresent
                         movementsPresent / movementsMissing
     - CellReplacement:  new = (old & ~clear) | set   (objects and movements;
                         movementsClear already includes movementsLayerMask)
     - rule groups loop until stable; movement resolution loops until stable;
       late rules; win conditions (no/some/all X [on Y]).
     - commands: cancel restart win again checkpoint message
     - undo ring, restart, checkpoints.

   Each PuzzleScript object (5x5 sprite) is pre-scaled by the exporter to a
   16x16 tile = 4 SMS subtiles, stored as 8 rows x (1 mask byte + 4 planar
   bytes) per subtile (160 bytes per object) so cells can be composited
   bottom-to-top with per-pixel transparency at runtime.

   Toolchain: SDCC + devkitSMS (SMSlib, crt0_sms, ihx2sms).
   ============================================================================

   GAME DATA FORMAT (bank 2, offsets relative to 0x8000)
   -----------------------------------------------------
   header:
     +0   char[4]  "PSMS"
     +4   u8       version (1)
     +5   u8       objectCount   (1..32)
     +6   u8       layerCount    (1..6)
     +7   u8       levelCount    (1..255)
     +8   u8       flags         bit0 run_rules_on_level_start
                                 bit1 noaction
                                 bit2 noundo
                                 bit3 norestart
     +9   u8       againFrames   (delay between 'again' turns)
     +10  u8[2]    reserved
     +12  u32      playerMask
     +16  u32[6]   layerMasks
     +40  u8[32]   objLayer      (layer index of each object)
     +72  u8[32]   drawOrder     (object ids bottom->top, 0xFF padded)
     +104 u8[16]   palette       (SMS colour bytes; [0]=background, [15]=text)
     +120 farptr   gfx           (objectCount * 160 bytes)
     +123 farptr   rules         (early rule groups blob)
     +126 farptr   lateRules
     +129 farptr   winConds
     +132 farptr   levelIndex    (levelCount * farptr)
     +135 char[34] title
     +169 char[34] author

   farptr = { u8 bank; u16 offset_in_bank (0..0x3FFF) }   bank 0xFF = null

   rules blob:      u8 groupCount, then per group:
                      u8 ruleCount, then per rule:
                        u8 dirMask (1 up,2 down,4 left,8 right)
                        u8 flags   (bit0 isRandom)
                        u8 commandBits (1 cancel,2 restart,4 win,8 again,
                                        16 checkpoint,32 message)
                        farptr message
                        u8 rowCount, then per row:
                          u8 cellCount, then per cell:
                            u8  cflags (bit0 hasReplacement,
                                        bit1 hasRandomEntity,
                                        bit2 hasRandomDir)
                            u8  anyCount
                            u32 objectsPresent, objectsMissing
                            u32 movementsPresent, movementsMissing
                            u32 anyMasks[anyCount]
                            if hasReplacement:
                              u32 objectsClear, objectsSet
                              u32 movementsClear, movementsSet
                              if hasRandomEntity: u32 randomEntityMask
                              if hasRandomDir:    u32 randomDirMask

   winConds blob:   u8 count, then per condition:
                      u8 type (0 NO, 1 SOME, 2 ALL)
                      u8 aggr (bit0: mask1 is aggregate, bit1: mask2 is)
                      u32 mask1, u32 mask2

   level:           u8 type; type 0: u8 w, u8 h, u32 cells[w*h] column-major
                             type 1: zero-terminated message text
   ========================================================================= */

#include "lib/SMSlib.h"

extern const unsigned char font_1bpp[768];

SMS_EMBED_SEGA_ROM_HEADER(9999, 0);

typedef unsigned char  u8;
typedef unsigned int   u16;
typedef unsigned long  u32;

#define GAME_DATA_BANK   2
#define SLOT2_BASE       ((const u8 *)0x8000)

#define MAX_W            16
#define MAX_H            12
#define MAX_CELLS        (MAX_W * MAX_H)
#define MAX_LAYERS       6
#define UNDO_DEPTH       3
#define MAX_COMBOS       86
#define COMBO_TILE_BASE  4
#define FONT_TILE_BASE   352
#define GROUP_ITER_CAP   60
#define AGAIN_CAP        250

#define DIR_UP     1
#define DIR_DOWN   2
#define DIR_LEFT   4
#define DIR_RIGHT  8
#define DIR_ACTION 16

#define CMD_CANCEL     1
#define CMD_RESTART    2
#define CMD_WIN        4
#define CMD_AGAIN      8
#define CMD_CHECKPOINT 16
#define CMD_MESSAGE    32

#define HDR_FLAG_RUNRULESONSTART 1
#define HDR_FLAG_NOACTION        2
#define HDR_FLAG_NOUNDO          4
#define HDR_FLAG_NORESTART       8

/* ------------------------------------------------------------------ RAM -- */

static u32 lv_objects[MAX_CELLS];              /* current cell masks        */
static u32 lv_movements[MAX_CELLS];            /* 5 bits per layer          */
static u32 prev_objects[MAX_CELLS];            /* last-drawn, for dirty     */
static u32 undo_ring[UNDO_DEPTH][MAX_CELLS];
static u32 checkpoint_buf[MAX_CELLS];

static u8  undo_count, undo_head;
static u8  checkpoint_valid;

static u8  lv_w, lv_h;
static u8  cur_level;
static u8  off_x, off_y;                       /* tilemap offset of cell 0  */

/* header mirror (copied from ROM so any bank can be mapped afterwards) */
static u8  hdr_object_count, hdr_layer_count, hdr_level_count;
static u8  hdr_flags, hdr_again_frames;
static u32 hdr_player_mask;
static u32 hdr_layer_masks[MAX_LAYERS];
static u8  hdr_obj_layer[32];
static u8  hdr_draw_order[32];
static u8  hdr_palette[16];
static u8  gfx_fp[3], rules_fp[3], late_fp[3], win_fp[3], levels_fp[3];
static char hdr_title[34], hdr_author[34];

/* combo cache: cell mask -> VRAM tile base */
static u32 combo_key[MAX_COMBOS];
static u16 combo_tile[MAX_COMBOS];
static u8  combo_count;

static u8  composite_buf[128];                 /* 4 subtiles x 32 bytes     */

/* per-turn state */
static u8  turn_commands;
static u8  turn_msg_fp[3];
static u32 level_content_mask;                 /* OR of all cells           */

/* rule-match scratch */
static u8  match_row_count;
static const u8 *match_row_ptr[6];             /* row blob starts           */
static u8  match_row_len[6];
static int match_row_pos[6];                   /* matched cell index / row  */
static signed char match_dx, match_dy;
static int match_didx;
static u8  match_rule_applied;
static u8  match_is_random;
static u16 match_rand_seen;                    /* reservoir counter         */
static u8  rng_state_a, rng_state_b;

/* ------------------------------------------------------- tiny helpers --- */

static u16 rd16(const u8 *p) { return (u16)p[0] | ((u16)p[1] << 8); }

static u32 rd32(const u8 *p)
{
    return (u32)p[0] | ((u32)p[1] << 8) | ((u32)p[2] << 16) | ((u32)p[3] << 24);
}

/* map a farptr's bank, return pointer into slot 2 */
static const u8 *far_map(const u8 *fp)
{
    SMS_mapROMBank(fp[0]);
    return SLOT2_BASE + (rd16(fp + 1) & 0x3FFF);
}

static u8 far_is_null(const u8 *fp) { return fp[0] == 0xFF; }

static u8 rng_next(void)
{
    /* 8-bit xorshift-ish, seeded by frame count at first input */
    rng_state_a ^= rng_state_a << 3;
    rng_state_a ^= rng_state_a >> 5;
    rng_state_a ^= rng_state_b++;
    return rng_state_a;
}

static void mem_copy32(u32 *dst, const u32 *src, u16 n)
{
    while (n--) *dst++ = *src++;
}

static u8 mem_equal32(const u32 *a, const u32 *b, u16 n)
{
    while (n--) if (*a++ != *b++) return 0;
    return 1;
}

static void mem_zero32(u32 *dst, u16 n) { while (n--) *dst++ = 0; }

/* ------------------------------------------------------------- text ----- */

static void print_at(u8 x, u8 y, const char *s)
{
    SMS_setNextTileatXY(x, y);
    while (*s) {
        u8 c = (u8)*s++;
        if (c < 32 || c > 127) c = '?';
        SMS_setTile(FONT_TILE_BASE + (c - 32));
    }
}

static void print_centered(u8 y, const char *s)
{
    u8 len = 0;
    const char *p = s;
    while (*p++) len++;
    if (len > 32) len = 32;
    print_at((32 - len) / 2, y, s);
}

static void clear_screen(void)
{
    u8 x, y;
    for (y = 0; y < 24; y++) {
        SMS_setNextTileatXY(0, y);
        for (x = 0; x < 32; x++) SMS_setTile(0);
    }
}

/* word-wrapped message text, centered vertically-ish */
static void draw_message_text(const char *s)
{
    char line[29];
    u8 y = 8;
    while (*s && y < 22) {
        u8 n = 0, last_space = 0;
        while (s[n] && s[n] != '\n' && n < 28) {
            if (s[n] == ' ') last_space = n;
            n++;
        }
        if (s[n] && s[n] != '\n' && last_space > 0) n = last_space;
        {
            u8 i;
            for (i = 0; i < n; i++) line[i] = s[i];
            line[n] = 0;
        }
        print_centered(y, line);
        s += n;
        while (*s == ' ' || *s == '\n') s++;
        y += 2;
    }
}

static u16 wait_button(void)
{
    u16 k;
    /* wait release first */
    do { SMS_waitForVBlank(); } while (SMS_getKeysStatus() & 0x3F30);
    do { SMS_waitForVBlank(); rng_next(); k = SMS_getKeysPressed(); } while (!(k & 0x3F30));
    return k;
}

/* --------------------------------------------------------- rendering ---- */

static void combo_reset(void)
{
    combo_count = 0;
}

/* composite one object's 160-byte gfx into composite_buf */
static void composite_object(const u8 *g)
{
    u8 s, r, p;
    u8 *dst = composite_buf;
    for (s = 0; s < 4; s++) {
        for (r = 0; r < 8; r++) {
            u8 m = *g++;
            u8 nm = (u8)~m;
            for (p = 0; p < 4; p++) {
                *dst = (*dst & nm) | *g++;
                dst++;
            }
        }
    }
}

/* build (or fetch) the 2x2 tile block for a cell mask; returns tile base */
static u16 combo_for_mask(u32 mask)
{
    u8 i;
    u16 tile;
    const u8 *gfx;

    if (mask == 0) return 0;
    for (i = 0; i < combo_count; i++)
        if (combo_key[i] == mask) return combo_tile[i];

    /* compose a new one */
    {
        u8 *b = composite_buf;
        u8 k = 128;
        while (k--) *b++ = 0;
    }
    gfx = far_map(gfx_fp);
    for (i = 0; i < 32; i++) {
        u8 obj = hdr_draw_order[i];
        if (obj == 0xFF) break;
        if (mask & ((u32)1 << obj))
            composite_object(gfx + (u16)obj * 160);
    }

    if (combo_count >= MAX_COMBOS) {
        /* out of VRAM slots: reuse the last slot (visual fallback) */
        tile = combo_tile[MAX_COMBOS - 1];
    } else {
        tile = COMBO_TILE_BASE + (u16)combo_count * 4;
        combo_key[combo_count]  = mask;
        combo_tile[combo_count] = tile;
        combo_count++;
    }
    SMS_loadTiles(composite_buf, tile, 128);
    return tile;
}

static void draw_cell(u8 cx, u8 cy)
{
    u32 mask = lv_objects[(u16)cx * lv_h + cy];
    u16 t = combo_for_mask(mask);
    u8 x = off_x + cx * 2, y = off_y + cy * 2;
    if (t == 0) {
        SMS_setTileatXY(x, y, 0);     SMS_setTileatXY(x + 1, y, 0);
        SMS_setTileatXY(x, y + 1, 0); SMS_setTileatXY(x + 1, y + 1, 0);
    } else {
        SMS_setTileatXY(x, y, t);         SMS_setTileatXY(x + 1, y, t + 1);
        SMS_setTileatXY(x, y + 1, t + 2); SMS_setTileatXY(x + 1, y + 1, t + 3);
    }
}

static void draw_all(void)
{
    u8 x, y;
    clear_screen();
    for (x = 0; x < lv_w; x++)
        for (y = 0; y < lv_h; y++)
            draw_cell(x, y);
    mem_copy32(prev_objects, lv_objects, MAX_CELLS);
}

static void draw_dirty(void)
{
    u8 x, y;
    u16 i = 0;
    for (x = 0; x < lv_w; x++)
        for (y = 0; y < lv_h; y++, i++)
            if (prev_objects[(u16)x * lv_h + y] != lv_objects[(u16)x * lv_h + y])
                draw_cell(x, y);
    mem_copy32(prev_objects, lv_objects, MAX_CELLS);
}

/* ------------------------------------------------------ level loading --- */

static void recompute_content_mask(void)
{
    u16 i;
    u16 n = (u16)lv_w * lv_h;
    level_content_mask = 0;
    for (i = 0; i < n; i++) level_content_mask |= lv_objects[i];
}

static const u8 *level_ptr(u8 n)
{
    const u8 *idx = far_map(levels_fp);
    u8 fp[3];
    fp[0] = idx[(u16)n * 3];
    fp[1] = idx[(u16)n * 3 + 1];
    fp[2] = idx[(u16)n * 3 + 2];
    return far_map(fp);
}

static u8 level_is_message(u8 n)
{
    return *level_ptr(n) == 1;
}

/* load map-type level into RAM */
static void load_level_data(u8 n)
{
    const u8 *p = level_ptr(n);
    u16 i, cells;
    p++;                                   /* type byte */
    lv_w = *p++;
    lv_h = *p++;
    cells = (u16)lv_w * lv_h;
    for (i = 0; i < cells; i++) {
        lv_objects[i] = rd32(p);
        p += 4;
    }
    mem_zero32(lv_movements, MAX_CELLS);
    off_x = (32 - lv_w * 2) / 2;
    off_y = (24 - lv_h * 2) / 2;
    undo_count = 0;
    undo_head = 0;
    checkpoint_valid = 0;
    combo_reset();
    recompute_content_mask();
}

/* ------------------------------------------------- rule interpretation -- */

/* Cursor helpers.  IMPORTANT: these take the ROM cursor by value and RETURN
   the advanced pointer.  Do NOT convert them to `const u8 **pp` in/out
   parameters: SDCC 4.2 (-mz80 --opt-code-speed) mis-optimises loops around
   calls that mutate a stack local through an escaped pointer (it elides the
   loop-top re-initialisation of the cursor), which corrupts rule parsing.
   Outputs are passed through the g_cell/g_match/g_changed globals instead. */

static u8  g_cell_flags, g_cell_any;
static u32 g_cell_op, g_cell_om, g_cell_mp, g_cell_mm;
static u8  g_match;                    /* result of cell_match             */
static u8  g_changed;                  /* accumulated by cell_apply        */

static const u8 *read_cell_header(const u8 *p)
{
    g_cell_flags = p[0];
    g_cell_any   = p[1];
    g_cell_op = rd32(p + 2);
    g_cell_om = rd32(p + 6);
    g_cell_mp = rd32(p + 10);
    g_cell_mm = rd32(p + 14);
    return p + 18;
}

static const u8 *skip_cell_tail(const u8 *p)
{
    p += (u16)g_cell_any * 4;
    if (g_cell_flags & 1) {
        p += 16;
        if (g_cell_flags & 2) p += 4;
        if (g_cell_flags & 4) p += 4;
    }
    return p;
}

/* match the cell pattern at p against level index idx; sets g_match,
   returns pointer past the whole cell (incl. anyMasks and replacement) */
static const u8 *cell_match(const u8 *p, int idx)
{
    u32 objs = lv_objects[idx];
    u32 movs = lv_movements[idx];
    u8 ok = 1;
    u8 n;

    p = read_cell_header(p);

    if ((objs & g_cell_op) != g_cell_op) ok = 0;
    else if (objs & g_cell_om) ok = 0;
    else if ((movs & g_cell_mp) != g_cell_mp) ok = 0;
    else if (movs & g_cell_mm) ok = 0;

    for (n = 0; n < g_cell_any; n++) {
        u32 am = rd32(p);
        p += 4;
        if (ok && !(objs & am)) ok = 0;
    }
    if (g_cell_flags & 1) {
        p += 16;
        if (g_cell_flags & 2) p += 4;
        if (g_cell_flags & 4) p += 4;
    }
    g_match = ok;
    return p;
}

/* apply the replacement of the cell at p to level index idx; ORs any
   change into g_changed, returns pointer past the whole cell */
static const u8 *cell_apply(const u8 *p, int idx)
{
    p = read_cell_header(p);
    p += (u16)g_cell_any * 4;

    if (g_cell_flags & 1) {
        u32 oc = rd32(p);      u32 os = rd32(p + 4);
        u32 mc = rd32(p + 8);  u32 ms = rd32(p + 12);
        u32 old_o = lv_objects[idx];
        u32 old_m = lv_movements[idx];
        u32 new_o, new_m;
        p += 16;

        if (g_cell_flags & 2) {                 /* random entity */
            u32 rem = rd32(p); p += 4;
            u8 nbits = 0, i, pick_n, pick = 0;
            for (i = 0; i < 32; i++)
                if (rem & ((u32)1 << i)) nbits++;
            if (nbits) {
                pick_n = rng_next() % nbits;
                for (i = 0; i < 32; i++)
                    if (rem & ((u32)1 << i)) {
                        if (pick_n == 0) { pick = i; break; }
                        pick_n--;
                    }
                os |= (u32)1 << pick;
                oc |= hdr_layer_masks[hdr_obj_layer[pick]];
                mc |= (u32)0x1F << (hdr_obj_layer[pick] * 5);
            }
        }
        if (g_cell_flags & 4) {                 /* random direction */
            u32 rdm = rd32(p); p += 4;
            u8 layer;
            for (layer = 0; layer < hdr_layer_count; layer++)
                if (rdm & ((u32)1 << (layer * 5)))
                    ms |= (u32)1 << ((rng_next() & 3) + layer * 5);
        }

        new_o = (old_o & ~oc) | os;
        new_m = (old_m & ~mc) | ms;
        if (new_o != old_o || new_m != old_m) {
            lv_objects[idx] = new_o;
            lv_movements[idx] = new_m;
            level_content_mask |= new_o;
            g_changed = 1;
        }
    }
    return p;
}

/* verify a whole cell-row still matches starting at cell index pos */
static u8 verify_row(const u8 *p, u8 ncells, int pos)
{
    u8 i;
    for (i = 0; i < ncells; i++) {
        p = cell_match(p, pos);
        if (!g_match) return 0;
        pos += match_didx;
    }
    return 1;
}

static void apply_row(const u8 *p, u8 ncells, int pos)
{
    u8 i;
    for (i = 0; i < ncells; i++) {
        p = cell_apply(p, pos);
        pos += match_didx;
    }
}

/* apply the whole rule at the currently matched tuple */
static void apply_tuple(void)
{
    u8 r;
    /* re-verify (earlier applications may have invalidated the match) */
    for (r = 0; r < match_row_count; r++)
        if (!verify_row(match_row_ptr[r], match_row_len[r], match_row_pos[r]))
            return;
    g_changed = 0;
    for (r = 0; r < match_row_count; r++)
        apply_row(match_row_ptr[r], match_row_len[r], match_row_pos[r]);
    if (g_changed) match_rule_applied = 1;
}

/* does at least one full match of every row exist on the board?  used to
   trigger commands of rules that match without changing anything. */
static u8 rule_tuple_exists(void)
{
    u8 r;
    for (r = 0; r < match_row_count; r++) {
        signed char x, y, x0, x1, y0, y1;
        u8 ncells = match_row_len[r];
        u8 found = 0;
        x0 = 0; x1 = (signed char)lv_w - 1;
        y0 = 0; y1 = (signed char)lv_h - 1;
        if (match_dx > 0) x1 = (signed char)lv_w - ncells;
        if (match_dx < 0) x0 = (signed char)(ncells - 1);
        if (match_dy > 0) y1 = (signed char)lv_h - ncells;
        if (match_dy < 0) y0 = (signed char)(ncells - 1);
        for (x = x0; x <= x1 && !found; x++)
            for (y = y0; y <= y1 && !found; y++)
                if (verify_row(match_row_ptr[r], ncells, (int)x * lv_h + y))
                    found = 1;
        if (!found) return 0;
    }
    return 1;
}

/* recursive cartesian enumeration over rows.
   deterministic rules: apply at every full tuple (with re-verification).
   random rules: reservoir-sample one tuple into match_rand_pos, applied
   by the caller after enumeration. */
static int match_rand_pos[6];

static void enum_rows(u8 row)
{
    u8 ncells;
    signed char x, y;
    signed char x0, x1, y0, y1;

    if (row == match_row_count) {
        if (match_is_random) {
            u8 r;
            match_rand_seen++;
            if ((rng_next() % match_rand_seen) == 0)
                for (r = 0; r < match_row_count; r++)
                    match_rand_pos[r] = match_row_pos[r];
        } else {
            apply_tuple();
        }
        return;
    }

    ncells = match_row_len[row];

    /* candidate start range so the whole row stays in bounds */
    x0 = 0; x1 = (signed char)lv_w - 1;
    y0 = 0; y1 = (signed char)lv_h - 1;
    if (match_dx > 0) x1 = (signed char)lv_w - ncells;
    if (match_dx < 0) x0 = (signed char)(ncells - 1);
    if (match_dy > 0) y1 = (signed char)lv_h - ncells;
    if (match_dy < 0) y0 = (signed char)(ncells - 1);
    if (x1 < x0 || y1 < y0) return;

    for (x = x0; x <= x1; x++) {
        for (y = y0; y <= y1; y++) {
            int pos = (int)x * lv_h + y;
            if (verify_row(match_row_ptr[row], ncells, pos)) {
                match_row_pos[row] = pos;
                enum_rows(row + 1);
            }
        }
    }
}

/* parse & run one rule starting at p; returns pointer past the rule.
   sets g_rule_applied if it changed the level; merges commands of a
   matching rule into turn_commands. */
static u8 g_rule_applied;

static const u8 *run_rule(const u8 *p)
{
    u8 dir = p[0];
    u8 flags = p[1];
    u8 cmd = p[2];
    const u8 *msg = p + 3;
    u8 nrows = p[6];
    u8 r, i;
    u8 matched_any;

    p += 7;
    match_row_count = nrows;
    for (r = 0; r < nrows; r++) {
        u8 ncells = *p++;
        match_row_len[r] = ncells;
        match_row_ptr[r] = p;
        for (i = 0; i < ncells; i++) {
            p = read_cell_header(p);
            p = skip_cell_tail(p);
        }
    }

    switch (dir) {
        case DIR_UP:    match_dx = 0;  match_dy = -1; break;
        case DIR_DOWN:  match_dx = 0;  match_dy = 1;  break;
        case DIR_LEFT:  match_dx = -1; match_dy = 0;  break;
        default:        match_dx = 1;  match_dy = 0;  break;
    }
    match_didx = (int)match_dx * lv_h + match_dy;

    match_rule_applied = 0;
    match_is_random = flags & 1;
    match_rand_seen = 0;
    enum_rows(0);

    if (match_is_random && match_rand_seen) {
        for (r = 0; r < match_row_count; r++)
            match_row_pos[r] = match_rand_pos[r];
        apply_tuple();
    }

    /* a rule "matched" if it applied a change, or (for command-only
       rules) if a full tuple exists on the board right now */
    matched_any = match_rule_applied;
    if (!matched_any && cmd)
        matched_any = match_is_random ? (match_rand_seen != 0)
                                      : rule_tuple_exists();

    if (matched_any && cmd) {
        turn_commands |= cmd;
        if ((cmd & CMD_MESSAGE) && turn_msg_fp[0] == 0xFF) {
            turn_msg_fp[0] = msg[0];
            turn_msg_fp[1] = msg[1];
            turn_msg_fp[2] = msg[2];
        }
    }
    g_rule_applied = match_rule_applied;
    return p;
}

/* run all rule groups in a blob (early or late) */
static void run_rule_groups(const u8 *fp)
{
    const u8 *base;
    const u8 *group_start;
    const u8 *p;
    u8 group_count, g, rule_count, iter, any, r;

    if (far_is_null(fp)) return;
    base = far_map(fp);
    group_count = *base;
    base++;

    for (g = 0; g < group_count; g++) {
        group_start = base;
        rule_count = *group_start;
        iter = 0;

        do {
            any = 0;
            p = group_start + 1;
            for (r = 0; r < rule_count; r++) {
                p = run_rule(p);
                any |= g_rule_applied;
            }
            iter++;
            if (turn_commands & CMD_CANCEL) any = 0;
        } while (any && iter < GROUP_ITER_CAP);
        base = p;                      /* p now points past the group */
    }
}

/* ------------------------------------------------- movement resolution -- */

static u8 try_reposition(int idx, u8 layer, u8 dirbits)
{
    signed char dx = 0, dy = 0;
    u8 tx, ty;
    int tgt;
    u32 layer_mask, moving;

    switch (dirbits) {
        case DIR_UP:    dy = -1; break;
        case DIR_DOWN:  dy = 1;  break;
        case DIR_LEFT:  dx = -1; break;
        case DIR_RIGHT: dx = 1;  break;
        case DIR_ACTION: return 1;     /* action: consumed in place */
        default: return 1;             /* garbage/multi-bit: clear it */
    }

    tx = idx / lv_h; ty = idx % lv_h;
    if ((tx == 0 && dx < 0) || (tx == lv_w - 1 && dx > 0) ||
        (ty == 0 && dy < 0) || (ty == lv_h - 1 && dy > 0))
        return 0;

    tgt = idx + (int)dx * lv_h + dy;
    layer_mask = hdr_layer_masks[layer];
    if (lv_objects[tgt] & layer_mask) return 0;      /* blocked */

    moving = lv_objects[idx] & layer_mask;
    lv_objects[idx] &= ~layer_mask;
    lv_objects[tgt] |= moving;
    return 1;
}

static void resolve_movements(void)
{
    u16 n = (u16)lv_w * lv_h;
    u8 moved;
    do {
        u16 i;
        moved = 0;
        for (i = 0; i < n; i++) {
            u32 m = lv_movements[i];
            u8 layer;
            if (!m) continue;
            for (layer = 0; layer < hdr_layer_count; layer++) {
                u8 lm = (u8)(m >> (layer * 5)) & 0x1F;
                if (lm && try_reposition((int)i, layer, lm)) {
                    m &= ~((u32)0x1F << (layer * 5));
                    lv_movements[i] = m;
                    moved = 1;
                }
            }
        }
    } while (moved);
    mem_zero32(lv_movements, MAX_CELLS);
}

/* --------------------------------------------------- win conditions ----- */

static u8 win_filter(u32 cell, u32 mask, u8 aggr)
{
    if (aggr) return (cell & mask) == mask;
    return (cell & mask) != 0;
}

static u8 check_win_conditions(void)
{
    const u8 *p;
    u8 count, c;
    u16 n = (u16)lv_w * lv_h;

    if (far_is_null(win_fp)) return 0;
    p = far_map(win_fp);
    count = *p++;
    if (count == 0) return 0;

    for (c = 0; c < count; c++) {
        u8 type = p[0], aggr = p[1];
        u32 m1 = rd32(p + 2), m2 = rd32(p + 6);
        u16 i;
        u8 pass = 1;
        p += 10;

        if (type == 0) {                       /* NO */
            for (i = 0; i < n; i++)
                if (win_filter(lv_objects[i], m1, aggr & 1) &&
                    win_filter(lv_objects[i], m2, aggr & 2)) { pass = 0; break; }
        } else if (type == 1) {                /* SOME */
            pass = 0;
            for (i = 0; i < n; i++)
                if (win_filter(lv_objects[i], m1, aggr & 1) &&
                    win_filter(lv_objects[i], m2, aggr & 2)) { pass = 1; break; }
        } else {                               /* ALL */
            for (i = 0; i < n; i++)
                if (win_filter(lv_objects[i], m1, aggr & 1) &&
                    !win_filter(lv_objects[i], m2, aggr & 2)) { pass = 0; break; }
        }
        if (!pass) return 0;
    }
    return 1;
}

/* --------------------------------------------------------- undo ring ---- */

static void undo_push(const u32 *snapshot)
{
    mem_copy32(undo_ring[undo_head], snapshot, MAX_CELLS);
    undo_head = (undo_head + 1) % UNDO_DEPTH;
    if (undo_count < UNDO_DEPTH) undo_count++;
}

static u8 undo_pop(void)
{
    if (!undo_count) return 0;
    undo_head = (undo_head + UNDO_DEPTH - 1) % UNDO_DEPTH;
    undo_count--;
    mem_copy32(lv_objects, undo_ring[undo_head], MAX_CELLS);
    mem_zero32(lv_movements, MAX_CELLS);
    recompute_content_mask();
    return 1;
}

/* --------------------------------------------------------- messages ----- */

static void show_message_fp(const u8 *fp)
{
    const char *txt;
    if (far_is_null(fp)) return;
    txt = (const char *)far_map(fp);
    clear_screen();
    draw_message_text(txt);
    print_centered(21, "- PRESS BUTTON -");
    wait_button();
    combo_for_mask(0);   /* no-op keeps compiler happy about unused paths */
    draw_all();
}

/* ------------------------------------------------------------ turn ------ */

/* returns: 0 nothing, 1 changed, 2 win, 3 restart-happened, 4 again */
static u32 turn_backup[MAX_CELLS];

static u8 do_turn(u8 dirmask, u8 push_undo)
{
    u8 changed;

    mem_copy32(turn_backup, lv_objects, MAX_CELLS);
    mem_zero32(lv_movements, MAX_CELLS);
    turn_commands = 0;
    turn_msg_fp[0] = 0xFF;

    if (dirmask) {
        u16 n = (u16)lv_w * lv_h;
        u16 i;
        for (i = 0; i < n; i++) {
            if (lv_objects[i] & hdr_player_mask) {
                u8 layer;
                for (layer = 0; layer < hdr_layer_count; layer++)
                    if (lv_objects[i] & hdr_layer_masks[layer] & hdr_player_mask)
                        lv_movements[i] |= (u32)dirmask << (layer * 5);
            }
        }
    }

    run_rule_groups(rules_fp);
    if (!(turn_commands & CMD_CANCEL)) {
        resolve_movements();
        run_rule_groups(late_fp);
    }

    if (turn_commands & CMD_CANCEL) {
        mem_copy32(lv_objects, turn_backup, MAX_CELLS);
        mem_zero32(lv_movements, MAX_CELLS);
        recompute_content_mask();
        return 0;
    }

    changed = !mem_equal32(lv_objects, turn_backup, MAX_CELLS);

    if (turn_commands & CMD_RESTART) return 3;

    if (changed && push_undo) undo_push(turn_backup);

    if (turn_commands & CMD_CHECKPOINT) {
        mem_copy32(checkpoint_buf, lv_objects, MAX_CELLS);
        checkpoint_valid = 1;
    }

    draw_dirty();

    if (turn_commands & CMD_MESSAGE) show_message_fp(turn_msg_fp);
    if (turn_commands & CMD_WIN) return 2;
    if (check_win_conditions()) return 2;
    if ((turn_commands & CMD_AGAIN) && changed) return 4;
    return changed;
}

static void do_restart(void)
{
    if (checkpoint_valid) {
        mem_copy32(lv_objects, checkpoint_buf, MAX_CELLS);
        mem_zero32(lv_movements, MAX_CELLS);
        recompute_content_mask();
    } else {
        u8 cp = checkpoint_valid;
        load_level_data(cur_level);
        checkpoint_valid = cp;
    }
    draw_all();
}

/* --------------------------------------------------------- game flow ---- */

static void read_header(void)
{
    const u8 *h;
    u8 i;
    SMS_mapROMBank(GAME_DATA_BANK);
    h = SLOT2_BASE;
    hdr_object_count = h[5];
    hdr_layer_count  = h[6];
    hdr_level_count  = h[7];
    hdr_flags        = h[8];
    hdr_again_frames = h[9];
    hdr_player_mask  = rd32(h + 12);
    for (i = 0; i < MAX_LAYERS; i++) hdr_layer_masks[i] = rd32(h + 16 + i * 4);
    for (i = 0; i < 32; i++) hdr_obj_layer[i]  = h[40 + i];
    for (i = 0; i < 32; i++) hdr_draw_order[i] = h[72 + i];
    for (i = 0; i < 16; i++) hdr_palette[i]    = h[104 + i];
    for (i = 0; i < 3; i++) {
        gfx_fp[i]    = h[120 + i];
        rules_fp[i]  = h[123 + i];
        late_fp[i]   = h[126 + i];
        win_fp[i]    = h[129 + i];
        levels_fp[i] = h[132 + i];
    }
    for (i = 0; i < 33; i++) hdr_title[i]  = h[135 + i];
    hdr_title[33] = 0;
    for (i = 0; i < 33; i++) hdr_author[i] = h[169 + i];
    hdr_author[33] = 0;
}

static void title_screen(void)
{
    clear_screen();
    print_centered(6, hdr_title);
    if (hdr_author[0]) {
        print_centered(9, "BY");
        print_centered(10, hdr_author);
    }
    print_centered(14, "PRESS 1 TO START");
    print_centered(17, "D-PAD MOVE");
    if (!(hdr_flags & HDR_FLAG_NOACTION)) print_centered(18, "1 ACTION");
    print_centered(19, "2 UNDO  HOLD 2 RESTART");
    print_centered(22, "PUZZLESCRIPT SMS");
    wait_button();
}

static void win_screen(void)
{
    clear_screen();
    print_centered(10, "CONGRATULATIONS!");
    print_centered(13, "THANK YOU FOR PLAYING");
    wait_button();
}

static void start_level(u8 n);

static void level_start_rules(void)
{
    if (hdr_flags & HDR_FLAG_RUNRULESONSTART) {
        u8 res = do_turn(0, 0);
        u8 again_guard = 0;
        while (res == 4 && again_guard++ < AGAIN_CAP)
            res = do_turn(0, 0);
        /* a win here is ignored, like PuzzleScript's level-start pass */
        if (res == 3) do_restart();
    }
}

static void start_level(u8 n)
{
    cur_level = n;
    load_level_data(n);
    draw_all();
    level_start_rules();
}

static void run_again_chain(u8 first_result)
{
    u8 res = first_result;
    u16 guard = 0;
    while (res == 4 && guard++ < AGAIN_CAP) {
        u8 f;
        for (f = 0; f < hdr_again_frames; f++) SMS_waitForVBlank();
        res = do_turn(0, 1);
        if (res == 2 || res == 3) break;
    }
    if (res == 2) {
        /* propagate win via global flag below */
        turn_commands |= CMD_WIN;
    } else if (res == 3) {
        do_restart();
    }
}

void main(void)
{
    u8 hold_dir = 0;
    u8 hold_frames = 0;
    u8 undo_hold = 0;

    SMS_setSpriteMode(SPRITEMODE_NORMAL);
    SMS_displayOff();
    SMS_VRAMmemsetW(0, 0x0000, 16384);

    read_header();

    SMS_loadBGPalette(hdr_palette);
    SMS_loadSpritePalette(hdr_palette);
    SMS_setBackdropColor(0);
    SMS_load1bppTiles(font_1bpp, FONT_TILE_BASE, 768, 0, 15);

    SMS_displayOn();

    for (;;) {
        u8 lvl = 0;
        title_screen();

        while (lvl < hdr_level_count) {
            if (level_is_message(lvl)) {
                const u8 *p = level_ptr(lvl);
                clear_screen();
                draw_message_text((const char *)(p + 1));
                print_centered(21, "- PRESS BUTTON -");
                wait_button();
                lvl++;
                continue;
            }

            start_level(lvl);

            /* -------- interactive loop for this level -------- */
            for (;;) {
                u16 keys, pressed;
                u8 dir = 0;
                u8 res = 0;

                SMS_waitForVBlank();
                rng_next();
                keys = SMS_getKeysStatus();
                pressed = SMS_getKeysPressed();

                /* undo (tap) / restart (hold ~1s) on button 2 */
                if (keys & PORT_A_KEY_2) {
                    undo_hold++;
                    if (undo_hold == 60) {
                        if (!(hdr_flags & HDR_FLAG_NORESTART)) {
                            do_restart();
                        }
                    }
                } else {
                    if (undo_hold > 0 && undo_hold < 60) {
                        if (!(hdr_flags & HDR_FLAG_NOUNDO) && undo_pop())
                            draw_all();
                    }
                    undo_hold = 0;
                }

                /* d-pad with hold-repeat */
                if      (keys & PORT_A_KEY_UP)    dir = DIR_UP;
                else if (keys & PORT_A_KEY_DOWN)  dir = DIR_DOWN;
                else if (keys & PORT_A_KEY_LEFT)  dir = DIR_LEFT;
                else if (keys & PORT_A_KEY_RIGHT) dir = DIR_RIGHT;

                if (dir) {
                    if (dir != hold_dir) {
                        hold_dir = dir;
                        hold_frames = 0;
                        res = do_turn(dir, 1);
                    } else {
                        hold_frames++;
                        if (hold_frames >= 18) {
                            hold_frames = 12;
                            res = do_turn(dir, 1);
                        }
                    }
                } else {
                    hold_dir = 0;
                    hold_frames = 0;
                }

                if (!res && (pressed & PORT_A_KEY_1) &&
                    !(hdr_flags & HDR_FLAG_NOACTION)) {
                    res = do_turn(DIR_ACTION, 1);
                }

                if (res == 4) {
                    turn_commands = 0;
                    run_again_chain(4);
                    if (turn_commands & CMD_WIN) res = 2;
                }
                if (res == 3) { do_restart(); continue; }
                if (res == 2) break;                       /* level won */
            }

            /* small win flourish */
            {
                u8 f;
                for (f = 0; f < 30; f++) SMS_waitForVBlank();
            }
            lvl++;
        }

        win_screen();
    }
}
