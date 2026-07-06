;--------------------------------------------------------
; File Created by SDCC : free open source ANSI-C Compiler
; Version 4.2.0 #13081 (Linux)
;--------------------------------------------------------
	.module ps_engine
	.optsdcc -mz80
	
;--------------------------------------------------------
; Public variables in this module
;--------------------------------------------------------
	.globl ___SMS__SEGA_signature
	.globl _main
	.globl _SMS_VRAMmemcpy
	.globl _SMS_getKeysPressed
	.globl _SMS_getKeysStatus
	.globl _SMS_loadSpritePalette
	.globl _SMS_loadBGPalette
	.globl _SMS_setBGPaletteColor
	.globl _SMS_copySpritestoSAT
	.globl _SMS_initSprites
	.globl _SMS_load1bppTiles
	.globl _SMS_crt0_RST18
	.globl _SMS_crt0_RST08
	.globl _SMS_waitForVBlank
	.globl _SMS_setBackdropColor
	.globl _SMS_VDPturnOffFeature
	.globl _SMS_VDPturnOnFeature
	.globl _SMS_SRAM
	.globl _SRAM_bank_to_be_mapped_on_slot2
	.globl _ROM_bank_to_be_mapped_on_slot0
	.globl _ROM_bank_to_be_mapped_on_slot1
	.globl _ROM_bank_to_be_mapped_on_slot2
	.globl _ps_font
;--------------------------------------------------------
; special function registers
;--------------------------------------------------------
_SMS_VDPControlPort	=	0x00bf
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
	.area _DATA
_ROM_bank_to_be_mapped_on_slot2	=	0xffff
_ROM_bank_to_be_mapped_on_slot1	=	0xfffe
_ROM_bank_to_be_mapped_on_slot0	=	0xfffd
_SRAM_bank_to_be_mapped_on_slot2	=	0xfffc
_SMS_SRAM	=	0x8000
_g_nobj:
	.ds 1
_g_nlayers:
	.ds 1
_g_nlevels:
	.ds 1
_g_flags:
	.ds 1
_g_again_interval:
	.ds 1
_g_textcol:
	.ds 1
_g_playerMask:
	.ds 4
_g_allMask:
	.ds 4
_g_layerMasks:
	.ds 24
_g_objLayer:
	.ds 32
_g_drawOrder:
	.ds 32
_g_palette:
	.ds 16
_g_far_tiles:
	.ds 3
_g_far_levels:
	.ds 3
_g_far_rules:
	.ds 3
_g_far_late:
	.ds 3
_g_far_win:
	.ds 3
_g_far_msgs:
	.ds 3
_g_title:
	.ds 32
_g_author:
	.ds 32
_lev:
	.ds 768
_mov:
	.ds 768
_bak:
	.ds 768
_chkpt:
	.ds 768
_undo_buf:
	.ds 2304
_undo_count:
	.ds 1
_undo_head:
	.ds 1
_g_w:
	.ds 1
_g_h:
	.ds 1
_g_ncells:
	.ds 1
_g_level_idx:
	.ds 1
_turn_cmd:
	.ds 1
_turn_msg:
	.ds 1
_pre_player:
	.ds 24
_rule_dx:
	.ds 1
_rule_dy:
	.ds 1
_rule_d:
	.ds 2
_rule_rowCount:
	.ds 1
_rule_hasRepl:
	.ds 1
_rule_rows:
	.ds 12
_rule_rowLen:
	.ds 6
_rule_pos:
	.ds 6
_rule_matched:
	.ds 1
_rule_changed:
	.ds 1
_msg_ptr:
	.ds 2
_combo_key:
	.ds 348
_combo_count:
	.ds 1
_cell_combo:
	.ds 192
_off_x:
	.ds 1
_off_y:
	.ds 1
_compose_buf:
	.ds 128
_frame_count:
	.ds 1
_poll_input_held_prev_65536_270:
	.ds 2
_poll_input_rep_timer_65536_270:
	.ds 1
_poll_input_hold2_65536_270:
	.ds 1
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
	.area _INITIALIZED
_rng_state:
	.ds 2
;--------------------------------------------------------
; absolute external ram data
;--------------------------------------------------------
	.area _DABS (ABS)
;--------------------------------------------------------
; global & static initialisations
;--------------------------------------------------------
	.area _HOME
	.area _GSINIT
	.area _GSFINAL
	.area _GSINIT
;--------------------------------------------------------
; Home
;--------------------------------------------------------
	.area _HOME
	.area _HOME
;--------------------------------------------------------
; code
;--------------------------------------------------------
	.area _CODE
;ps_engine.c:74: static u8 *map_bank(u8 rel_bank) {
;	---------------------------------
; Function map_bank
; ---------------------------------
_map_bank:
;ps_engine.c:75: SMS_mapROMBank(GAME_BANK + rel_bank);
	add	a, #0x02
	ld	(_ROM_bank_to_be_mapped_on_slot2+0), a
;ps_engine.c:76: return (u8 *)0x8000;
	ld	de, #0x8000
;ps_engine.c:77: }
	ret
_ps_font:
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x00	; 0
	.db #0x18	; 24
	.db #0x00	; 0
	.db #0x6c	; 108	'l'
	.db #0x6c	; 108	'l'
	.db #0x6c	; 108	'l'
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x36	; 54	'6'
	.db #0x36	; 54	'6'
	.db #0x7f	; 127
	.db #0x36	; 54	'6'
	.db #0x7f	; 127
	.db #0x36	; 54	'6'
	.db #0x36	; 54	'6'
	.db #0x00	; 0
	.db #0x0c	; 12
	.db #0x3f	; 63
	.db #0x68	; 104	'h'
	.db #0x3e	; 62
	.db #0x0b	; 11
	.db #0x7e	; 126
	.db #0x18	; 24
	.db #0x00	; 0
	.db #0x60	; 96
	.db #0x66	; 102	'f'
	.db #0x0c	; 12
	.db #0x18	; 24
	.db #0x30	; 48	'0'
	.db #0x66	; 102	'f'
	.db #0x06	; 6
	.db #0x00	; 0
	.db #0x38	; 56	'8'
	.db #0x6c	; 108	'l'
	.db #0x6c	; 108	'l'
	.db #0x38	; 56	'8'
	.db #0x6d	; 109	'm'
	.db #0x66	; 102	'f'
	.db #0x3b	; 59
	.db #0x00	; 0
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x0c	; 12
	.db #0x18	; 24
	.db #0x30	; 48	'0'
	.db #0x30	; 48	'0'
	.db #0x30	; 48	'0'
	.db #0x18	; 24
	.db #0x0c	; 12
	.db #0x00	; 0
	.db #0x30	; 48	'0'
	.db #0x18	; 24
	.db #0x0c	; 12
	.db #0x0c	; 12
	.db #0x0c	; 12
	.db #0x18	; 24
	.db #0x30	; 48	'0'
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x18	; 24
	.db #0x7e	; 126
	.db #0x3c	; 60
	.db #0x7e	; 126
	.db #0x18	; 24
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x7e	; 126
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x30	; 48	'0'
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x7e	; 126
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x06	; 6
	.db #0x0c	; 12
	.db #0x18	; 24
	.db #0x30	; 48	'0'
	.db #0x60	; 96
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x3c	; 60
	.db #0x66	; 102	'f'
	.db #0x6e	; 110	'n'
	.db #0x7e	; 126
	.db #0x76	; 118	'v'
	.db #0x66	; 102	'f'
	.db #0x3c	; 60
	.db #0x00	; 0
	.db #0x18	; 24
	.db #0x38	; 56	'8'
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x7e	; 126
	.db #0x00	; 0
	.db #0x3c	; 60
	.db #0x66	; 102	'f'
	.db #0x06	; 6
	.db #0x0c	; 12
	.db #0x18	; 24
	.db #0x30	; 48	'0'
	.db #0x7e	; 126
	.db #0x00	; 0
	.db #0x3c	; 60
	.db #0x66	; 102	'f'
	.db #0x06	; 6
	.db #0x1c	; 28
	.db #0x06	; 6
	.db #0x66	; 102	'f'
	.db #0x3c	; 60
	.db #0x00	; 0
	.db #0x0c	; 12
	.db #0x1c	; 28
	.db #0x3c	; 60
	.db #0x6c	; 108	'l'
	.db #0x7e	; 126
	.db #0x0c	; 12
	.db #0x0c	; 12
	.db #0x00	; 0
	.db #0x7e	; 126
	.db #0x60	; 96
	.db #0x7c	; 124
	.db #0x06	; 6
	.db #0x06	; 6
	.db #0x66	; 102	'f'
	.db #0x3c	; 60
	.db #0x00	; 0
	.db #0x1c	; 28
	.db #0x30	; 48	'0'
	.db #0x60	; 96
	.db #0x7c	; 124
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x3c	; 60
	.db #0x00	; 0
	.db #0x7e	; 126
	.db #0x06	; 6
	.db #0x0c	; 12
	.db #0x18	; 24
	.db #0x30	; 48	'0'
	.db #0x30	; 48	'0'
	.db #0x30	; 48	'0'
	.db #0x00	; 0
	.db #0x3c	; 60
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x3c	; 60
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x3c	; 60
	.db #0x00	; 0
	.db #0x3c	; 60
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x3e	; 62
	.db #0x06	; 6
	.db #0x0c	; 12
	.db #0x38	; 56	'8'
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x00	; 0
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x00	; 0
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x30	; 48	'0'
	.db #0x0c	; 12
	.db #0x18	; 24
	.db #0x30	; 48	'0'
	.db #0x60	; 96
	.db #0x30	; 48	'0'
	.db #0x18	; 24
	.db #0x0c	; 12
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x7e	; 126
	.db #0x00	; 0
	.db #0x7e	; 126
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x30	; 48	'0'
	.db #0x18	; 24
	.db #0x0c	; 12
	.db #0x06	; 6
	.db #0x0c	; 12
	.db #0x18	; 24
	.db #0x30	; 48	'0'
	.db #0x00	; 0
	.db #0x3c	; 60
	.db #0x66	; 102	'f'
	.db #0x0c	; 12
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x00	; 0
	.db #0x18	; 24
	.db #0x00	; 0
	.db #0x3c	; 60
	.db #0x66	; 102	'f'
	.db #0x6e	; 110	'n'
	.db #0x6a	; 106	'j'
	.db #0x6e	; 110	'n'
	.db #0x60	; 96
	.db #0x3c	; 60
	.db #0x00	; 0
	.db #0x3c	; 60
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x7e	; 126
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x00	; 0
	.db #0x7c	; 124
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x7c	; 124
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x7c	; 124
	.db #0x00	; 0
	.db #0x3c	; 60
	.db #0x66	; 102	'f'
	.db #0x60	; 96
	.db #0x60	; 96
	.db #0x60	; 96
	.db #0x66	; 102	'f'
	.db #0x3c	; 60
	.db #0x00	; 0
	.db #0x78	; 120	'x'
	.db #0x6c	; 108	'l'
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x6c	; 108	'l'
	.db #0x78	; 120	'x'
	.db #0x00	; 0
	.db #0x7e	; 126
	.db #0x60	; 96
	.db #0x60	; 96
	.db #0x7c	; 124
	.db #0x60	; 96
	.db #0x60	; 96
	.db #0x7e	; 126
	.db #0x00	; 0
	.db #0x7e	; 126
	.db #0x60	; 96
	.db #0x60	; 96
	.db #0x7c	; 124
	.db #0x60	; 96
	.db #0x60	; 96
	.db #0x60	; 96
	.db #0x00	; 0
	.db #0x3c	; 60
	.db #0x66	; 102	'f'
	.db #0x60	; 96
	.db #0x6e	; 110	'n'
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x3c	; 60
	.db #0x00	; 0
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x7e	; 126
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x00	; 0
	.db #0x7e	; 126
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x7e	; 126
	.db #0x00	; 0
	.db #0x3e	; 62
	.db #0x0c	; 12
	.db #0x0c	; 12
	.db #0x0c	; 12
	.db #0x0c	; 12
	.db #0x6c	; 108	'l'
	.db #0x38	; 56	'8'
	.db #0x00	; 0
	.db #0x66	; 102	'f'
	.db #0x6c	; 108	'l'
	.db #0x78	; 120	'x'
	.db #0x70	; 112	'p'
	.db #0x78	; 120	'x'
	.db #0x6c	; 108	'l'
	.db #0x66	; 102	'f'
	.db #0x00	; 0
	.db #0x60	; 96
	.db #0x60	; 96
	.db #0x60	; 96
	.db #0x60	; 96
	.db #0x60	; 96
	.db #0x60	; 96
	.db #0x7e	; 126
	.db #0x00	; 0
	.db #0x63	; 99	'c'
	.db #0x77	; 119	'w'
	.db #0x7f	; 127
	.db #0x6b	; 107	'k'
	.db #0x6b	; 107	'k'
	.db #0x63	; 99	'c'
	.db #0x63	; 99	'c'
	.db #0x00	; 0
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x76	; 118	'v'
	.db #0x7e	; 126
	.db #0x6e	; 110	'n'
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x00	; 0
	.db #0x3c	; 60
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x3c	; 60
	.db #0x00	; 0
	.db #0x7c	; 124
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x7c	; 124
	.db #0x60	; 96
	.db #0x60	; 96
	.db #0x60	; 96
	.db #0x00	; 0
	.db #0x3c	; 60
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x6a	; 106	'j'
	.db #0x6c	; 108	'l'
	.db #0x36	; 54	'6'
	.db #0x00	; 0
	.db #0x7c	; 124
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x7c	; 124
	.db #0x6c	; 108	'l'
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x00	; 0
	.db #0x3c	; 60
	.db #0x66	; 102	'f'
	.db #0x60	; 96
	.db #0x3c	; 60
	.db #0x06	; 6
	.db #0x66	; 102	'f'
	.db #0x3c	; 60
	.db #0x00	; 0
	.db #0x7e	; 126
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x00	; 0
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x3c	; 60
	.db #0x00	; 0
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x3c	; 60
	.db #0x18	; 24
	.db #0x00	; 0
	.db #0x63	; 99	'c'
	.db #0x63	; 99	'c'
	.db #0x6b	; 107	'k'
	.db #0x6b	; 107	'k'
	.db #0x7f	; 127
	.db #0x77	; 119	'w'
	.db #0x63	; 99	'c'
	.db #0x00	; 0
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x3c	; 60
	.db #0x18	; 24
	.db #0x3c	; 60
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x00	; 0
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x3c	; 60
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x00	; 0
	.db #0x7e	; 126
	.db #0x06	; 6
	.db #0x0c	; 12
	.db #0x18	; 24
	.db #0x30	; 48	'0'
	.db #0x60	; 96
	.db #0x7e	; 126
	.db #0x00	; 0
	.db #0x7c	; 124
	.db #0x60	; 96
	.db #0x60	; 96
	.db #0x60	; 96
	.db #0x60	; 96
	.db #0x60	; 96
	.db #0x7c	; 124
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x60	; 96
	.db #0x30	; 48	'0'
	.db #0x18	; 24
	.db #0x0c	; 12
	.db #0x06	; 6
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x3e	; 62
	.db #0x06	; 6
	.db #0x06	; 6
	.db #0x06	; 6
	.db #0x06	; 6
	.db #0x06	; 6
	.db #0x3e	; 62
	.db #0x00	; 0
	.db #0x3c	; 60
	.db #0x66	; 102	'f'
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0xff	; 255
	.db #0x30	; 48	'0'
	.db #0x18	; 24
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x3c	; 60
	.db #0x06	; 6
	.db #0x3e	; 62
	.db #0x66	; 102	'f'
	.db #0x3e	; 62
	.db #0x00	; 0
	.db #0x60	; 96
	.db #0x60	; 96
	.db #0x7c	; 124
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x7c	; 124
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x3c	; 60
	.db #0x66	; 102	'f'
	.db #0x60	; 96
	.db #0x66	; 102	'f'
	.db #0x3c	; 60
	.db #0x00	; 0
	.db #0x06	; 6
	.db #0x06	; 6
	.db #0x3e	; 62
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x3e	; 62
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x3c	; 60
	.db #0x66	; 102	'f'
	.db #0x7e	; 126
	.db #0x60	; 96
	.db #0x3c	; 60
	.db #0x00	; 0
	.db #0x1c	; 28
	.db #0x30	; 48	'0'
	.db #0x30	; 48	'0'
	.db #0x7c	; 124
	.db #0x30	; 48	'0'
	.db #0x30	; 48	'0'
	.db #0x30	; 48	'0'
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x3e	; 62
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x3e	; 62
	.db #0x06	; 6
	.db #0x3c	; 60
	.db #0x60	; 96
	.db #0x60	; 96
	.db #0x7c	; 124
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x00	; 0
	.db #0x18	; 24
	.db #0x00	; 0
	.db #0x38	; 56	'8'
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x3c	; 60
	.db #0x00	; 0
	.db #0x18	; 24
	.db #0x00	; 0
	.db #0x38	; 56	'8'
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x70	; 112	'p'
	.db #0x60	; 96
	.db #0x60	; 96
	.db #0x66	; 102	'f'
	.db #0x6c	; 108	'l'
	.db #0x78	; 120	'x'
	.db #0x6c	; 108	'l'
	.db #0x66	; 102	'f'
	.db #0x00	; 0
	.db #0x38	; 56	'8'
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x3c	; 60
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x36	; 54	'6'
	.db #0x7f	; 127
	.db #0x6b	; 107	'k'
	.db #0x6b	; 107	'k'
	.db #0x63	; 99	'c'
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x7c	; 124
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x3c	; 60
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x3c	; 60
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x7c	; 124
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x7c	; 124
	.db #0x60	; 96
	.db #0x60	; 96
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x3e	; 62
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x3e	; 62
	.db #0x06	; 6
	.db #0x07	; 7
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x6c	; 108	'l'
	.db #0x76	; 118	'v'
	.db #0x60	; 96
	.db #0x60	; 96
	.db #0x60	; 96
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x3e	; 62
	.db #0x60	; 96
	.db #0x3c	; 60
	.db #0x06	; 6
	.db #0x7c	; 124
	.db #0x00	; 0
	.db #0x30	; 48	'0'
	.db #0x30	; 48	'0'
	.db #0x7c	; 124
	.db #0x30	; 48	'0'
	.db #0x30	; 48	'0'
	.db #0x30	; 48	'0'
	.db #0x1c	; 28
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x3e	; 62
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x3c	; 60
	.db #0x18	; 24
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x63	; 99	'c'
	.db #0x6b	; 107	'k'
	.db #0x6b	; 107	'k'
	.db #0x7f	; 127
	.db #0x36	; 54	'6'
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x66	; 102	'f'
	.db #0x3c	; 60
	.db #0x18	; 24
	.db #0x3c	; 60
	.db #0x66	; 102	'f'
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x66	; 102	'f'
	.db #0x3e	; 62
	.db #0x06	; 6
	.db #0x3c	; 60
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x7e	; 126
	.db #0x0c	; 12
	.db #0x18	; 24
	.db #0x30	; 48	'0'
	.db #0x7e	; 126
	.db #0x00	; 0
	.db #0x0c	; 12
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x70	; 112	'p'
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x0c	; 12
	.db #0x00	; 0
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x00	; 0
	.db #0x30	; 48	'0'
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x0e	; 14
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x30	; 48	'0'
	.db #0x00	; 0
	.db #0x31	; 49	'1'
	.db #0x6b	; 107	'k'
	.db #0x46	; 70	'F'
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0xff	; 255
	.db #0xff	; 255
	.db #0xff	; 255
	.db #0xff	; 255
	.db #0xff	; 255
	.db #0xff	; 255
	.db #0xff	; 255
	.db #0xff	; 255
;ps_engine.c:80: static u8  rd8 (const u8 *p) { return p[0]; }
;	---------------------------------
; Function rd8
; ---------------------------------
_rd8:
	ld	a, (hl)
	ret
;ps_engine.c:81: static u16 rd16(const u8 *p) { return (u16)p[0] | ((u16)p[1] << 8); }
;	---------------------------------
; Function rd16
; ---------------------------------
_rd16:
	ld	e, (hl)
	inc	hl
	ld	d, #0x00
	ld	l, (hl)
;	spillPairReg hl
;	spillPairReg hl
;	spillPairReg hl
	xor	a, a
	or	a, e
	ld	e, a
	ld	a, l
	or	a, d
	ld	d, a
	ret
;ps_engine.c:82: static u32 rd32(const u8 *p) {
;	---------------------------------
; Function rd32
; ---------------------------------
_rd32:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	iy, #-8
	add	iy, sp
	ld	sp, iy
	ex	de, hl
;ps_engine.c:83: return (u32)p[0] | ((u32)p[1] << 8) | ((u32)p[2] << 16) | ((u32)p[3] << 24);
	ld	a, (de)
	ld	-4 (ix), a
	xor	a, a
	ld	-3 (ix), a
	ld	-2 (ix), a
	ld	-1 (ix), a
	ld	l, e
;	spillPairReg hl
;	spillPairReg hl
	ld	h, d
;	spillPairReg hl
;	spillPairReg hl
	inc	hl
	ld	c, (hl)
	ld	b, #0x00
	ld	hl, #0x0000
	ld	h, l
;	spillPairReg hl
;	spillPairReg hl
	ld	l, b
;	spillPairReg hl
;	spillPairReg hl
	ld	b, c
	ld	c, #0x00
	ld	a, -4 (ix)
	or	a, c
	ld	-8 (ix), a
	ld	a, -3 (ix)
	or	a, b
	ld	-7 (ix), a
	ld	a, -2 (ix)
	or	a, l
	ld	-6 (ix), a
	ld	a, -1 (ix)
	or	a, h
	ld	-5 (ix), a
	ld	l, e
;	spillPairReg hl
;	spillPairReg hl
	ld	h, d
;	spillPairReg hl
;	spillPairReg hl
	inc	hl
	inc	hl
	ld	l, (hl)
;	spillPairReg hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	ld	bc, #0x0000
	ld	a, -8 (ix)
	or	a, c
	ld	-4 (ix), a
	ld	a, -7 (ix)
	or	a, b
	ld	-3 (ix), a
	ld	a, -6 (ix)
	or	a, l
	ld	-2 (ix), a
	ld	a, -5 (ix)
	or	a, h
	ld	-1 (ix), a
	ld	hl, #3
	add	hl, de
	ld	h, (hl)
;	spillPairReg hl
;	spillPairReg hl
	ld	bc, #0x0000
	ld	l, #0x00
;	spillPairReg hl
;	spillPairReg hl
	ld	a, -4 (ix)
	or	a, c
	ld	e, a
	ld	a, -3 (ix)
	or	a, b
	ld	d, a
	ld	a, -2 (ix)
	or	a, l
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	ld	a, -1 (ix)
	or	a, h
	ld	h, a
;	spillPairReg hl
;	spillPairReg hl
;ps_engine.c:84: }
	ld	sp, ix
	pop	ix
	ret
;ps_engine.c:87: static u8 *far_resolve(const u8 *p3) { return map_bank(p3[0]) + rd16(p3 + 1); }
;	---------------------------------
; Function far_resolve
; ---------------------------------
_far_resolve:
	ld	c, (hl)
	push	hl
	ld	a, c
	call	_map_bank
	pop	hl
	inc	hl
	push	de
	call	_rd16
	ex	de, hl
	pop	de
	add	hl, de
	ex	de, hl
	ret
;ps_engine.c:142: static u8 rng4(void) {              /* 2 random bits                           */
;	---------------------------------
; Function rng4
; ---------------------------------
_rng4:
;ps_engine.c:143: u16 s = rng_state;
	ld	bc, (_rng_state)
;ps_engine.c:144: s ^= s << 7; s ^= s >> 9; s ^= s << 8;
	ld	l, c
	ld	h, b
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	ld	a, c
	xor	a, l
	ld	c, a
	ld	a, b
	xor	a, h
	ld	b, a
	srl	a
	ld	e, a
	ld	d, #0x00
	ld	a, c
	xor	a, e
	ld	c, a
	ld	a, b
	xor	a, d
	ld	b, a
	ld	e, c
	xor	a, a
	xor	a, c
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	ld	a, e
	xor	a, b
	ld	h, a
;	spillPairReg hl
;	spillPairReg hl
;ps_engine.c:145: rng_state = s;
	ld	(_rng_state), hl
;ps_engine.c:146: return (u8)(s & 3);
	ld	a, l
	and	a, #0x03
;ps_engine.c:147: }
	ret
;ps_engine.c:148: static u8 rng_mod(u8 n) {
;	---------------------------------
; Function rng_mod
; ---------------------------------
_rng_mod:
	ld	e, a
;ps_engine.c:149: u16 s = rng_state;
	ld	bc, (_rng_state)
;ps_engine.c:150: s ^= s << 7; s ^= s >> 9; s ^= s << 8;
	ld	l, c
	ld	h, b
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	ld	a, c
	xor	a, l
	ld	c, a
	ld	a, b
	xor	a, h
	ld	b, a
	srl	a
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	ld	a, c
	xor	a, l
	ld	c, a
	ld	a, b
	xor	a, h
	ld	b, a
	ld	d, c
	xor	a, a
	xor	a, c
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	ld	a, d
	xor	a, b
	ld	h, a
;	spillPairReg hl
;	spillPairReg hl
;ps_engine.c:151: rng_state = s;
	ld	(_rng_state), hl
;ps_engine.c:152: return (u8)(s % n);
	ld	d, #0x00
	call	__moduint
	ld	a, e
;ps_engine.c:153: }
	ret
;ps_engine.c:189: static const u8 *cell_skip(const u8 *p) {
;	---------------------------------
; Function cell_skip
; ---------------------------------
_cell_skip:
	ex	de, hl
;ps_engine.c:191: p += 16;
	ld	hl, #0x0010
	add	hl, de
	ex	de, hl
;ps_engine.c:192: anyc = *p++;
	ld	a, (de)
	inc	de
;ps_engine.c:193: p += (u16)anyc << 2;
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	add	hl, hl
	add	hl, hl
	add	hl, de
	ex	de, hl
;ps_engine.c:194: hasRepl = *p++;
	ld	a, (de)
	inc	de
;ps_engine.c:195: if (hasRepl) p += 24;
	or	a, a
	ret	Z
	ld	hl, #0x0018
	add	hl, de
	ex	de, hl
;ps_engine.c:196: return p;
;ps_engine.c:197: }
	ret
;ps_engine.c:200: static u8 cell_matches(const u8 *p, u8 i) {
;	---------------------------------
; Function cell_matches
; ---------------------------------
_cell_matches:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	iy, #-14
	add	iy, sp
	ld	sp, iy
	ex	(sp), hl
;ps_engine.c:201: u32 c = lev[i], m = mov[i], v;
	ld	l, 4 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	add	hl, hl
	add	hl, hl
	ld	c, l
	ld	b, h
	ld	hl, #_lev
	add	hl, bc
	push	bc
	ex	de, hl
	ld	hl, #4
	add	hl, sp
	ex	de, hl
	ld	bc, #0x0004
	ldir
	pop	bc
	ld	hl, #_mov+0
	add	hl, bc
	ex	de, hl
	ld	hl, #6
	add	hl, sp
	ex	de, hl
	ld	bc, #0x0004
	ldir
;ps_engine.c:203: v = rd32(p);      if ((c & v) != v) return 0;   /* objectsPresent (all)   */
	pop	hl
	push	hl
	call	_rd32
	ex	de, hl
	ld	a, -12 (ix)
	and	a, l
	ld	-4 (ix), a
	ld	a, -11 (ix)
	and	a, h
	ld	-3 (ix), a
	ld	a, -10 (ix)
	and	a, e
	ld	-2 (ix), a
	ld	a, -9 (ix)
	and	a, d
	ld	-1 (ix), a
	ld	c, -4 (ix)
	ld	b, -3 (ix)
	cp	a, a
	sbc	hl, bc
	jr	NZ, 00151$
	ld	l, -2 (ix)
	ld	h, -1 (ix)
	cp	a, a
	sbc	hl, de
	jr	Z, 00102$
00151$:
	xor	a, a
	jp	00114$
00102$:
;ps_engine.c:204: v = rd32(p + 4);  if (c & v)        return 0;   /* objectsMissing         */
	pop	hl
	push	hl
	ld	de, #0x0004
	add	hl, de
	call	_rd32
	ld	-4 (ix), e
	ld	-3 (ix), d
	ld	-2 (ix), l
	ld	-1 (ix), h
	ld	c, -4 (ix)
	ld	b, -3 (ix)
	ld	e, -2 (ix)
	ld	d, -1 (ix)
	ld	a, c
	and	a, -12 (ix)
	ld	c, a
	ld	a, b
	and	a, -11 (ix)
	ld	b, a
	ld	a, e
	and	a, -10 (ix)
	ld	e, a
	ld	a, d
	and	a, -9 (ix)
	ld	d, a
	or	a, e
	or	a, b
	or	a, c
	jr	Z, 00104$
	xor	a, a
	jp	00114$
00104$:
;ps_engine.c:205: v = rd32(p + 8);  if ((m & v) != v) return 0;   /* movementsPresent       */
	pop	hl
	push	hl
	ld	de, #0x0008
	add	hl, de
	call	_rd32
	ex	de, hl
	ld	a, -8 (ix)
	and	a, l
	ld	-4 (ix), a
	ld	a, -7 (ix)
	and	a, h
	ld	-3 (ix), a
	ld	a, -6 (ix)
	and	a, e
	ld	-2 (ix), a
	ld	a, -5 (ix)
	and	a, d
	ld	-1 (ix), a
	ld	c, -4 (ix)
	ld	b, -3 (ix)
	cp	a, a
	sbc	hl, bc
	jr	NZ, 00152$
	ld	l, -2 (ix)
	ld	h, -1 (ix)
	cp	a, a
	sbc	hl, de
	jr	Z, 00106$
00152$:
	xor	a, a
	jr	00114$
00106$:
;ps_engine.c:206: v = rd32(p + 12); if (m & v)        return 0;   /* movementsMissing       */
	pop	hl
	push	hl
	ld	de, #0x000c
	add	hl, de
	call	_rd32
	ld	-4 (ix), e
	ld	-3 (ix), d
	ld	-2 (ix), l
	ld	-1 (ix), h
	ld	c, -4 (ix)
	ld	b, -3 (ix)
	ld	e, -2 (ix)
	ld	d, -1 (ix)
	ld	a, c
	and	a, -8 (ix)
	ld	c, a
	ld	a, b
	and	a, -7 (ix)
	ld	b, a
	ld	a, e
	and	a, -6 (ix)
	ld	e, a
	ld	a, d
	and	a, -5 (ix)
	ld	d, a
	or	a, e
	or	a, b
	or	a, c
	jr	Z, 00108$
	xor	a, a
	jr	00114$
00108$:
;ps_engine.c:207: p += 16;
	pop	hl
	push	hl
	ld	de, #0x0010
	add	hl, de
;ps_engine.c:208: anyc = *p++;
	ld	a, (hl)
	ld	-1 (ix), a
	inc	hl
;ps_engine.c:209: while (anyc--) {
00111$:
	ld	c, -1 (ix)
	dec	-1 (ix)
	ld	a, c
	or	a, a
	jr	Z, 00113$
;ps_engine.c:210: v = rd32(p); p += 4;
	push	hl
	call	_rd32
	ld	c, l
	ld	b, h
	pop	hl
	inc	hl
	inc	hl
	inc	hl
	inc	hl
;ps_engine.c:211: if (!(c & v)) return 0;                     /* anyObjectsPresent      */
	ld	a, e
	and	a, -12 (ix)
	ld	e, a
	ld	a, d
	and	a, -11 (ix)
	ld	d, a
	ld	a, c
	and	a, -10 (ix)
	ld	c, a
	ld	a, b
	and	a, -9 (ix)
	ld	b, a
	or	a, c
	or	a, d
	or	a, e
	jr	NZ, 00111$
	xor	a, a
	jr	00114$
00113$:
;ps_engine.c:213: return 1;
	ld	a, #0x01
00114$:
;ps_engine.c:214: }
	ld	sp, ix
	pop	ix
	pop	hl
	inc	sp
	jp	(hl)
;ps_engine.c:218: static u8 cell_apply(const u8 *p, u8 i) {
;	---------------------------------
; Function cell_apply
; ---------------------------------
_cell_apply:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	iy, #-62
	add	iy, sp
	ld	sp, iy
	ex	de, hl
;ps_engine.c:222: p += 16; anyc = *p++; p += (u16)anyc << 2;
	ld	hl, #0x0010
	add	hl, de
	ex	de, hl
	ld	a, (de)
	inc	de
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	add	hl, hl
	add	hl, hl
	add	hl, de
	ex	de, hl
;ps_engine.c:223: hasRepl = *p++;
	ld	a, (de)
	ld	c, a
	inc	de
	ld	-2 (ix), e
	ld	-1 (ix), d
;ps_engine.c:224: if (!hasRepl) return 0;
	ld	a, c
	or	a, a
	jr	NZ, 00102$
	xor	a, a
	jp	00122$
00102$:
;ps_engine.c:225: objClear = rd32(p);      objSet  = rd32(p + 4);
	ld	l, -2 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, -1 (ix)
;	spillPairReg hl
;	spillPairReg hl
	call	_rd32
	ld	-18 (ix), e
	ld	-17 (ix), d
	ld	-16 (ix), l
	ld	-15 (ix), h
	ld	l, -2 (ix)
	ld	h, -1 (ix)
	ld	de, #0x0004
	add	hl, de
	call	_rd32
	ld	-14 (ix), e
	ld	-13 (ix), d
	ld	-12 (ix), l
	ld	-11 (ix), h
;ps_engine.c:226: movClear = rd32(p + 8);  movSet  = rd32(p + 12);
	ld	l, -2 (ix)
	ld	h, -1 (ix)
	ld	de, #0x0008
	add	hl, de
	call	_rd32
	ld	-10 (ix), e
	ld	-9 (ix), d
	ld	-8 (ix), l
	ld	-7 (ix), h
	ld	l, -2 (ix)
	ld	h, -1 (ix)
	ld	de, #0x000c
	add	hl, de
	call	_rd32
	ld	-6 (ix), e
	ld	-5 (ix), d
	ld	-4 (ix), l
	ld	-3 (ix), h
;ps_engine.c:227: randEnt  = rd32(p + 16); randDir = rd32(p + 20);
	ld	l, -2 (ix)
	ld	h, -1 (ix)
	ld	de, #0x0010
	add	hl, de
	call	_rd32
	ld	c, e
	ld	b, d
	ex	de, hl
	ld	a, -2 (ix)
	add	a, #0x14
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	ld	a, -1 (ix)
	adc	a, #0x00
	ld	h, a
;	spillPairReg hl
;	spillPairReg hl
	push	bc
	push	de
	call	_rd32
	push	de
	pop	iy
	pop	de
	pop	bc
	push	iy
	ex	(sp), hl
	ld	-30 (ix), l
	ex	(sp), hl
	ex	(sp), hl
	ld	-29 (ix), h
	ex	(sp), hl
	pop	iy
	ld	-28 (ix), l
	ld	-27 (ix), h
;ps_engine.c:229: if (randEnt) {                       /* random object from a property     */
	ld	a, d
	or	a, e
	or	a, b
	or	a, c
	jp	Z, 00107$
;ps_engine.c:231: for (k = 0; k < g_nobj; k++)
	ld	-2 (ix), #0x00
	ld	-1 (ix), #0x00
00117$:
	ld	hl, #_g_nobj
	ld	a, -1 (ix)
	sub	a, (hl)
	jr	NC, 00105$
;ps_engine.c:232: if (randEnt & ((u32)1 << k)) choices[n++] = k;
	ld	a, -1 (ix)
	ld	-26 (ix), #0x01
	ld	-25 (ix), #0x00
	ld	-24 (ix), #0x00
	ld	-23 (ix), #0x00
	inc	a
	jr	00182$
00181$:
	sla	-26 (ix)
	rl	-25 (ix)
	rl	-24 (ix)
	rl	-23 (ix)
00182$:
	dec	a
	jr	NZ,00181$
	ld	a, c
	and	a, -26 (ix)
	ld	-22 (ix), a
	ld	a, b
	and	a, -25 (ix)
	ld	-21 (ix), a
	ld	a, e
	and	a, -24 (ix)
	ld	-20 (ix), a
	ld	a, d
	and	a, -23 (ix)
	ld	-19 (ix), a
	or	a, -20 (ix)
	or	a, -21 (ix)
	or	a, -22 (ix)
	jr	Z, 00118$
	push	de
	ld	e, -2 (ix)
	ld	d, #0x00
	ld	hl, #2
	add	hl, sp
	add	hl, de
	pop	de
	inc	-2 (ix)
	ld	a, -1 (ix)
	ld	(hl), a
00118$:
;ps_engine.c:231: for (k = 0; k < g_nobj; k++)
	inc	-1 (ix)
	jr	00117$
00105$:
;ps_engine.c:233: r = choices[rng_mod(n)];
	ld	a, -2 (ix)
	call	_rng_mod
	ld	e, a
	ld	d, #0x00
	ld	hl, #0
	add	hl, sp
	add	hl, de
	ld	b, (hl)
;ps_engine.c:234: lay = g_objLayer[r];
	ld	de, #_g_objLayer+0
	ld	l, b
	ld	h, #0x00
	add	hl, de
	ld	c, (hl)
;ps_engine.c:235: objSet   |= (u32)1 << r;
	ld	hl, #0x0001
	ld	de, #0x0000
	inc	b
	jr	00184$
00183$:
	add	hl, hl
	rl	e
	rl	d
00184$:
	djnz	00183$
	ld	a, -14 (ix)
	or	a, l
	ld	-14 (ix), a
	ld	a, -13 (ix)
	or	a, h
	ld	-13 (ix), a
	ld	a, -12 (ix)
	or	a, e
	ld	-12 (ix), a
	ld	a, -11 (ix)
	or	a, d
	ld	-11 (ix), a
;ps_engine.c:236: objClear |= g_layerMasks[lay];
	ld	l, c
;	spillPairReg hl
;	spillPairReg hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	add	hl, hl
	add	hl, hl
	ld	de, #_g_layerMasks
	add	hl, de
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	inc	hl
	inc	hl
	ld	a, (hl)
	dec	hl
	ld	l, (hl)
;	spillPairReg hl
	ld	h, a
;	spillPairReg hl
;	spillPairReg hl
	ld	a, -18 (ix)
	or	a, e
	ld	-18 (ix), a
	ld	a, -17 (ix)
	or	a, d
	ld	-17 (ix), a
	ld	a, -16 (ix)
	or	a, l
	ld	-16 (ix), a
	ld	a, -15 (ix)
	or	a, h
	ld	-15 (ix), a
;ps_engine.c:237: movClear |= (u32)0x1F << (lay + (lay << 2));  /* 5*lay */
	ld	a, c
	add	a, a
	add	a, a
	add	a, c
	ld	b, a
	ld	hl, #0x001f
	ld	de, #0x0000
	inc	b
	jr	00186$
00185$:
	add	hl, hl
	rl	e
	rl	d
00186$:
	djnz	00185$
	ld	a, -10 (ix)
	or	a, l
	ld	-10 (ix), a
	ld	a, -9 (ix)
	or	a, h
	ld	-9 (ix), a
	ld	a, -8 (ix)
	or	a, e
	ld	-8 (ix), a
	ld	a, -7 (ix)
	or	a, d
	ld	-7 (ix), a
00107$:
;ps_engine.c:239: if (randDir) {                       /* "randomdir" per layer             */
	ld	a, -27 (ix)
	or	a, -28 (ix)
	or	a, -29 (ix)
	or	a, -30 (ix)
	jp	Z, 00112$
;ps_engine.c:240: u8 sh = 0;
	ld	-19 (ix), #0x00
;ps_engine.c:241: for (k = 0; k < g_nlayers; k++, sh += 5)
	ld	-1 (ix), #0x00
00120$:
	ld	hl, #_g_nlayers
	ld	a, -1 (ix)
	sub	a, (hl)
	jr	NC, 00112$
;ps_engine.c:242: if (randDir & ((u32)1 << sh))
	ld	b, -19 (ix)
	ld	a, #0x01
	ld	e, #0x00
	ld	hl, #0x0000
	inc	b
	jr	00188$
00187$:
	add	a, a
	rl	e
	adc	hl, hl
00188$:
	djnz	00187$
	and	a, -30 (ix)
	ld	c, a
	ld	a, e
	and	a, -29 (ix)
	ld	b, a
	ld	a, l
	and	a, -28 (ix)
	ld	e, a
	ld	a, h
	and	a, -27 (ix)
	or	a, e
	or	a, b
	or	a, c
	jr	Z, 00121$
;ps_engine.c:243: movSet |= (u32)1 << (rng4() + sh);
	call	_rng4
	ld	-2 (ix), a
	add	a, -19 (ix)
	ld	e, a
	ld	hl, #0x0001
	ld	bc, #0x0000
	inc	e
	jr	00190$
00189$:
	add	hl, hl
	rl	c
	rl	b
00190$:
	dec	e
	jr	NZ,00189$
	ld	a, -6 (ix)
	or	a, l
	ld	-6 (ix), a
	ld	a, -5 (ix)
	or	a, h
	ld	-5 (ix), a
	ld	a, -4 (ix)
	or	a, c
	ld	-4 (ix), a
	ld	a, -3 (ix)
	or	a, b
	ld	-3 (ix), a
00121$:
;ps_engine.c:241: for (k = 0; k < g_nlayers; k++, sh += 5)
	inc	-1 (ix)
	ld	a, -19 (ix)
	add	a, #0x05
	ld	-19 (ix), a
	jr	00120$
00112$:
;ps_engine.c:246: nc = (lev[i] & ~objClear) | objSet;
	ld	e, 4 (ix)
	ld	d, #0x00
	ex	de, hl
	add	hl, hl
	add	hl, hl
	ex	de, hl
	ld	hl, #_lev
	add	hl, de
	ld	-2 (ix), l
	ld	-1 (ix), h
	push	de
	ld	e, -2 (ix)
	ld	d, -1 (ix)
	ld	hl, #42
	add	hl, sp
	ex	de, hl
	ld	bc, #0x0004
	ldir
	pop	de
	ld	a, -18 (ix)
	cpl
	ld	c, a
	ld	a, -17 (ix)
	cpl
	ld	b, a
	ld	a, -16 (ix)
	cpl
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	ld	a, -15 (ix)
	cpl
	push	af
	ld	a, -22 (ix)
	and	a, c
	ld	c, a
	ld	a, -21 (ix)
	and	a, b
	ld	b, a
	ld	a, -20 (ix)
	and	a, l
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	pop	af
	and	a, -19 (ix)
	ld	h, a
;	spillPairReg hl
;	spillPairReg hl
	ld	a, c
	or	a, -14 (ix)
	ld	c, a
	ld	a, b
	or	a, -13 (ix)
	ld	b, a
	ld	a, l
	or	a, -12 (ix)
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	ld	a, h
	or	a, -11 (ix)
	ld	h, a
;	spillPairReg hl
;	spillPairReg hl
	ld	-14 (ix), c
	ld	-13 (ix), b
	ld	-12 (ix), l
	ld	-11 (ix), h
;ps_engine.c:247: nm = (mov[i] & ~movClear) | movSet;
	ld	hl, #_mov
	add	hl, de
	ld	e, l
	ld	d, h
	inc	hl
	inc	hl
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
	dec	hl
	dec	hl
	ld	a, (hl)
	dec	hl
	ld	l, (hl)
;	spillPairReg hl
	ld	h, a
;	spillPairReg hl
;	spillPairReg hl
	ld	a, -10 (ix)
	cpl
	ld	-10 (ix), a
	ld	a, -9 (ix)
	cpl
	ld	-9 (ix), a
	ld	a, -8 (ix)
	cpl
	ld	-8 (ix), a
	ld	a, -7 (ix)
	cpl
	ld	-7 (ix), a
	ld	a, l
	and	a, -10 (ix)
	ld	-18 (ix), a
	ld	a, h
	and	a, -9 (ix)
	ld	-17 (ix), a
	ld	a, c
	and	a, -8 (ix)
	ld	-16 (ix), a
	ld	a, b
	and	a, -7 (ix)
	ld	-15 (ix), a
	ld	a, -18 (ix)
	or	a, -6 (ix)
	ld	-10 (ix), a
	ld	a, -17 (ix)
	or	a, -5 (ix)
	ld	-9 (ix), a
	ld	a, -16 (ix)
	or	a, -4 (ix)
	ld	-8 (ix), a
	ld	a, -15 (ix)
	or	a, -3 (ix)
	ld	-7 (ix), a
	ld	a, -10 (ix)
	ld	-6 (ix), a
	ld	a, -9 (ix)
	ld	-5 (ix), a
	ld	a, -8 (ix)
	ld	-4 (ix), a
	ld	a, -7 (ix)
	ld	-3 (ix), a
;ps_engine.c:248: if (nc == lev[i] && nm == mov[i]) return 0;
	ld	a, -14 (ix)
	sub	a, -22 (ix)
	jr	NZ, 00114$
	ld	a, -13 (ix)
	sub	a, -21 (ix)
	jr	NZ, 00114$
	ld	a, -12 (ix)
	sub	a, -20 (ix)
	jr	NZ, 00114$
	ld	a, -11 (ix)
	sub	a, -19 (ix)
	jr	NZ, 00114$
	ld	a, l
	sub	a, -6 (ix)
	jr	NZ, 00114$
	ld	a, h
	sub	a, -5 (ix)
	jr	NZ, 00114$
	ld	l, -4 (ix)
	ld	h, -3 (ix)
	cp	a, a
	sbc	hl, bc
	jr	NZ, 00114$
	xor	a, a
	jr	00122$
00114$:
;ps_engine.c:249: lev[i] = nc; mov[i] = nm;
	push	de
	ld	e, -2 (ix)
	ld	d, -1 (ix)
	ld	hl, #50
	add	hl, sp
	ld	bc, #0x0004
	ldir
	pop	de
	ld	hl, #56
	add	hl, sp
	ld	bc, #0x0004
	ldir
;ps_engine.c:250: return 1;
	ld	a, #0x01
00122$:
;ps_engine.c:251: }
	ld	sp, ix
	pop	ix
	pop	hl
	inc	sp
	jp	(hl)
;ps_engine.c:254: static u8 row_matches_at(u8 r, u8 i) {
;	---------------------------------
; Function row_matches_at
; ---------------------------------
_row_matches_at:
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
	push	af
	ld	c, a
	ld	b, l
;ps_engine.c:255: const u8 *p = rule_rows[r] + 1;
	ld	de, #_rule_rows+0
	ld	l, c
;	spillPairReg hl
;	spillPairReg hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	add	hl, hl
	add	hl, de
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	inc	de
	inc	sp
	inc	sp
	push	de
;ps_engine.c:256: u8 k, n = rule_rowLen[r];
	ld	de, #_rule_rowLen+0
	ld	l, c
	ld	h, #0x00
	add	hl, de
	ld	c, (hl)
;ps_engine.c:257: int idx = i;
	ld	-2 (ix), b
	ld	-1 (ix), #0x00
;ps_engine.c:258: for (k = 0; k < n; k++) {
	ld	b, #0x00
00105$:
	ld	a, b
	sub	a, c
	jr	NC, 00103$
;ps_engine.c:259: if (!cell_matches(p, (u8)idx)) return 0;
	ld	a, -2 (ix)
	push	bc
	push	af
	inc	sp
	ld	l, -4 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, -3 (ix)
;	spillPairReg hl
;	spillPairReg hl
	call	_cell_matches
	pop	bc
	or	a,a
	jr	Z, 00107$
;ps_engine.c:260: p = cell_skip(p);
	ld	e, c
	ld	d, b
	pop	hl
	push	hl
	push	de
	call	_cell_skip
	pop	bc
	inc	sp
	inc	sp
	push	de
;ps_engine.c:261: idx += rule_d;
	ld	a, -2 (ix)
	ld	hl, #_rule_d
	add	a, (hl)
	ld	-2 (ix), a
	ld	a, -1 (ix)
	inc	hl
	adc	a, (hl)
	ld	-1 (ix), a
;ps_engine.c:258: for (k = 0; k < n; k++) {
	inc	b
	jr	00105$
00103$:
;ps_engine.c:263: return 1;
	ld	a, #0x01
00107$:
;ps_engine.c:264: }
	ld	sp, ix
	pop	ix
	ret
;ps_engine.c:266: static void row_apply_at(u8 r, u8 i) {
;	---------------------------------
; Function row_apply_at
; ---------------------------------
_row_apply_at:
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
	ld	d, a
	ld	e, l
;ps_engine.c:267: const u8 *p = rule_rows[r] + 1;
	ld	bc, #_rule_rows+0
	ld	l, d
;	spillPairReg hl
;	spillPairReg hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	add	hl, hl
	add	hl, bc
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
	inc	bc
	inc	sp
	inc	sp
	push	bc
;ps_engine.c:268: u8 k, n = rule_rowLen[r];
	ld	bc, #_rule_rowLen+0
	ld	l, d
	ld	h, #0x00
	add	hl, bc
	ld	c, (hl)
;ps_engine.c:269: int idx = i;
;ps_engine.c:270: for (k = 0; k < n; k++) {
	ld	d, #0x00
	ld	b, d
00105$:
	ld	a, b
	sub	a, c
	jr	NC, 00107$
;ps_engine.c:271: if (cell_apply(p, (u8)idx)) rule_changed = 1;
	ld	a, e
	push	bc
	push	de
	push	af
	inc	sp
	ld	l, -2 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, -1 (ix)
;	spillPairReg hl
;	spillPairReg hl
	call	_cell_apply
	pop	de
	pop	bc
	or	a, a
	jr	Z, 00102$
	ld	hl, #_rule_changed
	ld	(hl), #0x01
00102$:
;ps_engine.c:272: p = cell_skip(p);
	push	bc
	push	de
	ld	l, -2 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, -1 (ix)
;	spillPairReg hl
;	spillPairReg hl
	call	_cell_skip
	ex	de, hl
	pop	de
	pop	bc
	ex	(sp), hl
;ps_engine.c:273: idx += rule_d;
	ld	a, e
	ld	iy, #_rule_d
	add	a, 0 (iy)
	ld	e, a
	ld	a, d
	adc	a, 1 (iy)
	ld	d, a
;ps_engine.c:270: for (k = 0; k < n; k++) {
	inc	b
	jr	00105$
00107$:
;ps_engine.c:275: }
	ld	sp, ix
	pop	ix
	ret
;ps_engine.c:279: static void scan_row(u8 r) {
;	---------------------------------
; Function scan_row
; ---------------------------------
_scan_row:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl, #-6
	add	hl, sp
	ld	sp, hl
	ld	-3 (ix), a
;ps_engine.c:280: u8 n = rule_rowLen[r];
	ld	bc, #_rule_rowLen+0
	ld	l, -3 (ix)
	ld	h, #0x00
	add	hl, bc
	ld	e, (hl)
;ps_engine.c:281: u8 x0 = 0, y0 = 0, x1 = g_w, y1 = g_h;   /* exclusive bounds              */
	ld	c, #0x00
	ld	-6 (ix), #0x00
	ld	a, (_g_w+0)
	ld	-5 (ix), a
	ld	a, (_g_h+0)
	ld	-4 (ix), a
;ps_engine.c:284: if (rule_dx > 0) { x1 = g_w - n + 1; }
	xor	a, a
	ld	hl, #_rule_dx
	sub	a, (hl)
	jp	PO, 00242$
	xor	a, #0x80
00242$:
	jp	P, 00108$
	ld	a, (_g_w+0)
	sub	a, e
	inc	a
	ld	-5 (ix), a
	jr	00109$
00108$:
;ps_engine.c:285: else if (rule_dx < 0) { x0 = n - 1; }
	ld	b, e
	dec	b
	ld	a, (_rule_dx+0)
	bit	7, a
	jr	Z, 00105$
	ld	c, b
	jr	00109$
00105$:
;ps_engine.c:286: else if (rule_dy > 0) { y1 = g_h - n + 1; }
	xor	a, a
	ld	hl, #_rule_dy
	sub	a, (hl)
	jp	PO, 00243$
	xor	a, #0x80
00243$:
	jp	P, 00102$
	ld	a, (_g_h+0)
	sub	a, e
	inc	a
	ld	-4 (ix), a
	jr	00109$
00102$:
;ps_engine.c:287: else { y0 = n - 1; }
	ld	-6 (ix), b
00109$:
;ps_engine.c:288: if (x1 > g_w || y1 > g_h) return;        /* row longer than board         */
	ld	a, (#_g_w)
	sub	a, -5 (ix)
	jp	C,00143$
	ld	a, (#_g_h)
	sub	a, -4 (ix)
;ps_engine.c:290: for (x = x0; x < x1; x++) {
	jp	C,00143$
00141$:
	ld	a, c
	sub	a, -5 (ix)
	jp	NC, 00143$
;ps_engine.c:291: i = (u8)(x * g_h + y0);
	ld	a, (#_g_h + 0)
	ld	e, a
	ld	h, c
;	spillPairReg hl
;	spillPairReg hl
	ld	l, #0x00
	ld	d, l
	ld	b, #0x08
00244$:
	add	hl, hl
	jr	NC, 00245$
	add	hl, de
00245$:
	djnz	00244$
	ld	a, l
	add	a, -6 (ix)
	ld	-2 (ix), a
;ps_engine.c:292: for (y = y0; y < y1; y++, i++) {
	ld	a, -6 (ix)
	ld	-1 (ix), a
00139$:
	ld	a, -1 (ix)
	sub	a, -4 (ix)
	jp	NC, 00142$
;ps_engine.c:293: if (!row_matches_at(r, i)) continue;
	push	bc
	ld	l, -2 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	a, -3 (ix)
	call	_row_matches_at
	pop	bc
	or	a, a
	jp	Z, 00129$
;ps_engine.c:294: rule_pos[r] = i;
	ld	a, #<(_rule_pos)
	add	a, -3 (ix)
	ld	e, a
	ld	a, #>(_rule_pos)
	adc	a, #0x00
	ld	d, a
	ld	a, -2 (ix)
	ld	(de), a
;ps_engine.c:295: if (r + 1 < rule_rowCount) {
	ld	e, -3 (ix)
	ld	d, #0x00
	inc	de
	ld	a, (_rule_rowCount+0)
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	ld	b, #0x00
	ld	a, e
	sub	a, l
	ld	a, d
	sbc	a, b
	jp	PO, 00246$
	xor	a, #0x80
00246$:
	jp	P, 00127$
;ps_engine.c:296: scan_row(r + 1);
	ld	b, -3 (ix)
	inc	b
	push	bc
	ld	a, b
	call	_scan_row
	pop	bc
;ps_engine.c:297: if (rule_matched && !rule_hasRepl) return;
	ld	a, (_rule_matched+0)
	or	a, a
	jr	Z, 00129$
	ld	a, (_rule_hasRepl+0)
	or	a, a
	jr	NZ, 00129$
	jr	00143$
00127$:
;ps_engine.c:299: rule_matched = 1;
	ld	hl, #_rule_matched
	ld	(hl), #0x01
;ps_engine.c:300: if (!rule_hasRepl) return;
	ld	a, (_rule_hasRepl+0)
	or	a, a
;ps_engine.c:303: for (k = 0; k < rule_rowCount; k++)
	jr	Z, 00143$
	ld	e, #0x00
00133$:
	ld	hl, #_rule_rowCount
	ld	a, e
	sub	a, (hl)
	jr	NC, 00122$
;ps_engine.c:304: if (!row_matches_at(k, rule_pos[k])) break;
	ld	hl, #_rule_pos
	ld	d, #0x00
	add	hl, de
	ld	l, (hl)
;	spillPairReg hl
	push	bc
	push	de
	ld	a, e
	call	_row_matches_at
	pop	de
	pop	bc
	or	a, a
	jr	Z, 00122$
;ps_engine.c:303: for (k = 0; k < rule_rowCount; k++)
	inc	e
	jr	00133$
00122$:
;ps_engine.c:305: if (k == rule_rowCount)
	ld	a, (_rule_rowCount+0)
;ps_engine.c:306: for (k = 0; k < rule_rowCount; k++)
	sub	a,e
	jr	NZ, 00129$
	ld	e,a
00136$:
	ld	hl, #_rule_rowCount
	ld	a, e
	sub	a, (hl)
	jr	NC, 00129$
;ps_engine.c:307: row_apply_at(k, rule_pos[k]);
	ld	hl, #_rule_pos
	ld	d, #0x00
	add	hl, de
	ld	l, (hl)
;	spillPairReg hl
	push	bc
	push	de
	ld	a, e
	call	_row_apply_at
	pop	de
	pop	bc
;ps_engine.c:306: for (k = 0; k < rule_rowCount; k++)
	inc	e
	jr	00136$
00129$:
;ps_engine.c:292: for (y = y0; y < y1; y++, i++) {
	inc	-1 (ix)
	inc	-2 (ix)
	jp	00139$
00142$:
;ps_engine.c:290: for (x = x0; x < x1; x++) {
	inc	c
	jp	00141$
00143$:
;ps_engine.c:311: }
	ld	sp, ix
	pop	ix
	ret
;ps_engine.c:314: static u8 rule_try_apply(const u8 *p) {
;	---------------------------------
; Function rule_try_apply
; ---------------------------------
_rule_try_apply:
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
	push	af
	ex	de, hl
;ps_engine.c:317: p += 2;                                  /* byteLen                       */
	inc	de
	inc	de
;ps_engine.c:318: dir = *p++;
	ld	a, (de)
	ld	c, a
	inc	de
;ps_engine.c:319: rule_hasRepl = *p++ & 1;
	ld	a, (de)
	inc	de
	and	a, #0x01
	ld	(_rule_hasRepl+0), a
;ps_engine.c:320: cmd = *p++;
	ld	a, (de)
	ld	-4 (ix), a
	inc	de
;ps_engine.c:321: msg = *p++;
	ld	a, (de)
	ld	-3 (ix), a
	inc	de
;ps_engine.c:322: rule_rowCount = *p++;
	ld	a, (de)
	ld	(_rule_rowCount+0), a
	inc	de
	ld	-2 (ix), e
	ld	-1 (ix), d
;ps_engine.c:324: rule_dx = 0; rule_dy = 0;
	ld	hl, #_rule_dx
	ld	(hl), #0x00
	ld	hl, #_rule_dy
	ld	(hl), #0x00
;ps_engine.c:325: switch (dir) {
	ld	a, c
	dec	a
	jr	Z, 00101$
	ld	a,c
	cp	a,#0x02
	jr	Z, 00102$
	sub	a, #0x04
	jr	Z, 00103$
	jr	00104$
;ps_engine.c:326: case 1: rule_dy = -1; break;
00101$:
	ld	hl, #_rule_dy
	ld	(hl), #0xff
	jr	00105$
;ps_engine.c:327: case 2: rule_dy =  1; break;
00102$:
	ld	hl, #_rule_dy
	ld	(hl), #0x01
	jr	00105$
;ps_engine.c:328: case 4: rule_dx = -1; break;
00103$:
	ld	hl, #_rule_dx
	ld	(hl), #0xff
	jr	00105$
;ps_engine.c:329: default: rule_dx = 1; break;
00104$:
	ld	hl, #_rule_dx
	ld	(hl), #0x01
;ps_engine.c:330: }
00105$:
;ps_engine.c:331: rule_d = (int)rule_dx * g_h + rule_dy;
	ld	a, (_rule_dx+0)
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	rlca
	sbc	a, a
	ld	h, a
;	spillPairReg hl
;	spillPairReg hl
	ld	a, (_g_h+0)
	ld	e, a
	ld	d, #0x00
	call	__mulint
	ld	a, (_rule_dy+0)
	ld	c, a
	rlca
	sbc	a, a
	ld	b, a
	ld	a, c
	ld	hl, #_rule_d
	add	a, e
	ld	(hl), a
	inc	hl
	ld	a, b
	adc	a, d
	ld	(hl), a
;ps_engine.c:333: for (r = 0; r < rule_rowCount; r++) {
	ld	c, #0x00
00117$:
	ld	hl, #_rule_rowCount
	ld	a, c
	sub	a, (hl)
	jr	NC, 00107$
;ps_engine.c:334: rule_rows[r] = p;
	ld	l, c
;	spillPairReg hl
;	spillPairReg hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	add	hl, hl
	ld	de, #_rule_rows
	add	hl, de
	ld	a, -2 (ix)
	ld	(hl), a
	inc	hl
	ld	a, -1 (ix)
	ld	(hl), a
;ps_engine.c:335: rule_rowLen[r] = *p;
	ld	a, #<(_rule_rowLen)
	add	a, c
	ld	b, a
	ld	a, #>(_rule_rowLen)
	adc	a, #0x00
	ld	l, -2 (ix)
	ld	h, -1 (ix)
	ld	e, (hl)
	ld	l, b
	ld	h, a
	ld	(hl), e
;ps_engine.c:336: q = p + 1;
	pop	hl
	pop	de
	push	de
	push	hl
	inc	de
;ps_engine.c:337: { u8 k; for (k = 0; k < rule_rowLen[r]; k++) q = cell_skip(q); }
	ld	-2 (ix), b
	ld	-1 (ix), a
	ld	b, #0x00
00114$:
	ld	l, -2 (ix)
	ld	h, -1 (ix)
	ld	l, (hl)
;	spillPairReg hl
	ld	a, b
	sub	a, l
	jr	NC, 00106$
	push	bc
	ex	de, hl
	call	_cell_skip
	pop	bc
	inc	b
	jr	00114$
00106$:
;ps_engine.c:338: p = q;
	ld	-2 (ix), e
	ld	-1 (ix), d
;ps_engine.c:333: for (r = 0; r < rule_rowCount; r++) {
	inc	c
	jr	00117$
00107$:
;ps_engine.c:341: rule_matched = 0; rule_changed = 0;
	ld	hl, #_rule_matched
	ld	(hl), #0x00
	ld	hl, #_rule_changed
	ld	(hl), #0x00
;ps_engine.c:342: scan_row(0);
	xor	a, a
	call	_scan_row
;ps_engine.c:343: if (rule_matched) {                      /* commands queue on match       */
	ld	a, (_rule_matched+0)
	or	a, a
	jr	Z, 00112$
;ps_engine.c:344: turn_cmd |= cmd;
	ld	a, (_turn_cmd+0)
	or	a, -4 (ix)
	ld	(_turn_cmd+0), a
;ps_engine.c:345: if ((cmd & CMD_MESSAGE) && turn_msg == 0xFF) turn_msg = msg;
	bit	5, -4 (ix)
	jr	Z, 00112$
	ld	a, (_turn_msg+0)
	inc	a
	jr	NZ, 00112$
	ld	a, -3 (ix)
	ld	(_turn_msg+0), a
00112$:
;ps_engine.c:347: return rule_changed;
	ld	a, (_rule_changed+0)
;ps_engine.c:348: }
	ld	sp, ix
	pop	ix
	ret
;ps_engine.c:351: static u8 apply_rule_group(const u8 *gp) {
;	---------------------------------
; Function apply_rule_group
; ---------------------------------
_apply_rule_group:
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
	push	af
	push	af
;ps_engine.c:352: u8 ruleCount = *gp, hasChanges = 0, made = 1;
	ld	a, (hl)
	ld	-6 (ix), a
	ld	-5 (ix), #0x00
	ld	c, #0x01
;ps_engine.c:354: while (made && ++loopcount < 200) {
	ex	de, hl
	inc	de
	ld	-4 (ix), #0x00
00110$:
	ld	a, c
	or	a, a
	jr	Z, 00112$
	inc	-4 (ix)
	ld	a, -4 (ix)
	sub	a, #0xc8
	jr	NC, 00112$
;ps_engine.c:355: const u8 *p = gp + 1;
	ld	-3 (ix), e
	ld	-2 (ix), d
;ps_engine.c:356: u8 ri, consecFail = 0;
	ld	-1 (ix), #0x00
;ps_engine.c:357: made = 0;
;ps_engine.c:358: for (ri = 0; ri < ruleCount; ri++) {
	ld	bc, #0x0
00114$:
	ld	a, b
	sub	a, -6 (ix)
	jr	NC, 00106$
;ps_engine.c:359: if (rule_try_apply(p)) { made = 1; consecFail = 0; }
	push	bc
	push	de
	ld	l, -3 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, -2 (ix)
;	spillPairReg hl
;	spillPairReg hl
	call	_rule_try_apply
	pop	de
	pop	bc
	or	a, a
	jr	Z, 00104$
	ld	c, #0x01
	ld	-1 (ix), #0x00
	jr	00105$
00104$:
;ps_engine.c:360: else if (++consecFail == ruleCount) break;
	inc	-1 (ix)
	ld	a, -1 (ix)
	sub	a, -6 (ix)
	jr	Z, 00106$
00105$:
;ps_engine.c:361: p += rd16(p);
	push	bc
	push	de
	ld	l, -3 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, -2 (ix)
;	spillPairReg hl
;	spillPairReg hl
	call	_rd16
	ex	de, hl
	pop	de
	pop	bc
	ld	a, l
	add	a, -3 (ix)
	ld	-3 (ix), a
	ld	a, h
	adc	a, -2 (ix)
	ld	-2 (ix), a
;ps_engine.c:358: for (ri = 0; ri < ruleCount; ri++) {
	inc	b
	jr	00114$
00106$:
;ps_engine.c:363: if (made) hasChanges = 1;
	ld	a, c
	or	a, a
	jr	Z, 00110$
	ld	-5 (ix), #0x01
	jr	00110$
00112$:
;ps_engine.c:365: return hasChanges;
	ld	a, -5 (ix)
;ps_engine.c:366: }
	ld	sp, ix
	pop	ix
	ret
;ps_engine.c:369: static void apply_rules(const u8 *far3) {
;	---------------------------------
; Function apply_rules
; ---------------------------------
_apply_rules:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	iy, #-12
	add	iy, sp
	ld	sp, iy
;ps_engine.c:370: const u8 *blob = far_resolve(far3);
	call	_far_resolve
	inc	sp
	inc	sp
;ps_engine.c:371: u8 groupCount = blob[0];
	ex	de,hl
	push	hl
	ld	a, (hl)
	ld	-10 (ix), a
;ps_engine.c:372: const u8 *loopPt  = blob + 1;
	ld	a, -12 (ix)
	add	a, #0x01
	ld	-9 (ix), a
	ld	a, -11 (ix)
	adc	a, #0x00
	ld	-8 (ix), a
;ps_engine.c:373: const u8 *offsets = blob + 1 + groupCount + 1;
	ld	a, -10 (ix)
	ld	-2 (ix), a
	ld	-1 (ix), #0x00
	ld	a, -2 (ix)
	add	a, #0x02
	ld	-4 (ix), a
	ld	a, -1 (ix)
	adc	a, #0x00
	ld	-3 (ix), a
	ld	a, -4 (ix)
	add	a, -12 (ix)
	ld	-2 (ix), a
	ld	a, -3 (ix)
	adc	a, -11 (ix)
	ld	-1 (ix), a
	ld	a, -2 (ix)
	ld	-7 (ix), a
	ld	a, -1 (ix)
	ld	-6 (ix), a
;ps_engine.c:374: u8 gi = 0, loopProp = 0, loopCount = 0;
	ld	-1 (ix), #0x00
	ld	-5 (ix), #0x00
	ld	-4 (ix), #0x00
;ps_engine.c:376: if (!groupCount) return;
	ld	a, -10 (ix)
	or	a, a
;ps_engine.c:377: while (gi < groupCount) {
	jp	Z,00119$
00116$:
	ld	a, -1 (ix)
	sub	a, -10 (ix)
	jp	NC, 00119$
;ps_engine.c:378: if (apply_rule_group(blob + rd16(offsets + ((u16)gi << 1))))
	ld	a, -1 (ix)
	ld	-3 (ix), a
	ld	-2 (ix), #0x00
	ld	l, a
	ld	h, #0x00
	add	hl, hl
	ld	e, -7 (ix)
	ld	d, -6 (ix)
	add	hl, de
	call	_rd16
	pop	hl
	push	hl
	add	hl, de
	call	_apply_rule_group
	or	a, a
	jr	Z, 00104$
;ps_engine.c:379: loopProp = 1;
	ld	-5 (ix), #0x01
00104$:
;ps_engine.c:382: if (++loopCount > 200) break;
	ld	a, -4 (ix)
	inc	a
	ld	-3 (ix), a
;ps_engine.c:380: if (loopProp && loopPt[gi] != 0xFF) {
	ld	a, -5 (ix)
	or	a, a
	jr	Z, 00108$
	ld	a, -9 (ix)
	add	a, -1 (ix)
	ld	c, a
	ld	a, -8 (ix)
	adc	a, #0x00
	ld	b, a
	ld	a, (bc)
	cp	a, #0xff
	jr	Z, 00108$
;ps_engine.c:381: gi = loopPt[gi]; loopProp = 0;
	ld	-1 (ix), a
	ld	-5 (ix), #0x00
;ps_engine.c:382: if (++loopCount > 200) break;
	ld	a, -3 (ix)
	ld	-4 (ix), a
	ld	a, #0xc8
	sub	a, -4 (ix)
	jr	NC, 00116$
	jr	00119$
;ps_engine.c:383: continue;
00108$:
;ps_engine.c:385: gi++;
	inc	-1 (ix)
;ps_engine.c:386: if (gi == groupCount && loopProp && loopPt[gi] != 0xFF) {
	ld	a, -1 (ix)
	sub	a, -10 (ix)
	jr	NZ, 00116$
	ld	a, -5 (ix)
	or	a, a
	jr	Z, 00116$
	ld	a, -9 (ix)
	add	a, -1 (ix)
	ld	c, a
	ld	a, -8 (ix)
	adc	a, #0x00
	ld	b, a
	ld	a, (bc)
	ld	-2 (ix), a
	inc	a
	jp	Z,00116$
;ps_engine.c:387: gi = loopPt[gi]; loopProp = 0;
	ld	a, -2 (ix)
	ld	-1 (ix), a
	ld	-5 (ix), #0x00
;ps_engine.c:388: if (++loopCount > 200) break;
	ld	a, -3 (ix)
	ld	-4 (ix), a
	ld	a, #0xc8
	sub	a, -4 (ix)
	jp	NC, 00116$
00119$:
;ps_engine.c:391: }
	ld	sp, ix
	pop	ix
	ret
;ps_engine.c:395: static u8 reposition(u8 i, u8 x, u8 y, u8 layer, u8 lm) {
;	---------------------------------
; Function reposition
; ---------------------------------
_reposition:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	iy, #-15
	add	iy, sp
	ld	sp, iy
	ld	c, a
	ld	-1 (ix), l
;ps_engine.c:396: s8 dx = 0, dy = 0;
	ld	b, #0x00
	ld	e, b
;ps_engine.c:400: switch (lm) {
	ld	a, 6 (ix)
	dec	a
	jr	Z, 00101$
	ld	a, 6 (ix)
	sub	a, #0x02
	jr	Z, 00102$
	ld	a, 6 (ix)
	sub	a, #0x04
	jr	Z, 00103$
	ld	a, 6 (ix)
	sub	a, #0x08
	jr	Z, 00104$
	jr	00106$
;ps_engine.c:401: case 1: dy = -1; break;
00101$:
	ld	e, #0xff
	jr	00106$
;ps_engine.c:402: case 2: dy =  1; break;
00102$:
	ld	e, #0x01
	jr	00106$
;ps_engine.c:403: case 4: dx = -1; break;
00103$:
	ld	b, #0xff
	jr	00106$
;ps_engine.c:404: case 8: dx =  1; break;
00104$:
	ld	b, #0x01
;ps_engine.c:406: }
00106$:
;ps_engine.c:407: if ((dx | dy) == 0) {
	ld	a, b
	or	a, e
	ld	d, a
	or	a, a
	jr	NZ, 00110$
;ps_engine.c:408: if (lm == 16) return 1;             /* action consumed, no motion     */
	ld	a, 6 (ix)
	sub	a, #0x10
	jr	NZ, 00108$
	ld	a, #0x01
	jp	00122$
00108$:
;ps_engine.c:409: return 0;                           /* '?' / weird masks: JS parity   */
	xor	a, a
	jp	00122$
00110$:
;ps_engine.c:411: if ((x == 0 && dx < 0) || (x == g_w - 1 && dx > 0) ||
	ld	a, -1 (ix)
	or	a, a
	jr	NZ, 00115$
	bit	7, b
	jr	NZ, 00111$
00115$:
	ld	a, (_g_w+0)
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	ld	l, a
	dec	hl
	ld	a, -1 (ix)
	ld	-3 (ix), a
	ld	-2 (ix), #0x00
	ld	a, l
	sub	a, -3 (ix)
	jr	NZ, 00117$
	ld	a, h
	sub	a, -2 (ix)
	jr	NZ, 00117$
	xor	a, a
	sub	a, b
	jp	PO, 00187$
	xor	a, #0x80
00187$:
	jp	M, 00111$
00117$:
;ps_engine.c:412: (y == 0 && dy < 0) || (y == g_h - 1 && dy > 0)) return 0;
	ld	a, 4 (ix)
	or	a, a
	jr	NZ, 00119$
	bit	7, e
	jr	NZ, 00111$
00119$:
	ld	a, (_g_h+0)
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	ld	l, a
	dec	hl
	ld	a, 4 (ix)
	ld	-3 (ix), a
	ld	-2 (ix), #0x00
	ld	a, l
	sub	a, -3 (ix)
	jr	NZ, 00112$
	ld	a, h
	sub	a, -2 (ix)
	jr	NZ, 00112$
	xor	a, a
	sub	a, e
	jp	PO, 00190$
	xor	a, #0x80
00190$:
	jp	P, 00112$
00111$:
	xor	a, a
	jp	00122$
00112$:
;ps_engine.c:414: ti = (u8)((int)i + (int)dx * g_h + dy);
	ld	d, c
	ld	a, (_g_h+0)
	push	de
	ld	e, a
	ld	h, b
;	spillPairReg hl
;	spillPairReg hl
	ld	l, #0x00
	ld	d, l
	ld	b, #0x08
00191$:
	add	hl, hl
	jr	NC, 00192$
	add	hl, de
00192$:
	djnz	00191$
	pop	de
	ld	a, d
	add	a, l
	add	a, e
	ld	b, a
;ps_engine.c:415: lmask = g_layerMasks[layer];
	ld	de, #_g_layerMasks+0
	ld	l, 5 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	add	hl, hl
	add	hl, hl
	add	hl, de
	push	bc
	ex	de, hl
	ld	hl, #2
	add	hl, sp
	ex	de, hl
	ld	bc, #0x0004
	ldir
	pop	bc
;ps_engine.c:416: if (lev[ti] & lmask) return 0;          /* layer collision                */
	ld	e, b
	ld	d, #0x00
	ex	de, hl
	add	hl, hl
	add	hl, hl
	ld	de, #_lev
	add	hl, de
	ld	-11 (ix), l
	ld	-10 (ix), h
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	inc	hl
	inc	hl
	ld	a, (hl)
	dec	hl
	ld	l, (hl)
;	spillPairReg hl
	ld	h, a
;	spillPairReg hl
;	spillPairReg hl
	ld	a, e
	and	a, -15 (ix)
	push	af
	ld	a, d
	and	a, -14 (ix)
	ld	b, a
	ld	a, l
	and	a, -13 (ix)
	ld	e, a
	ld	a, h
	and	a, -12 (ix)
	ld	d, a
	pop	af
	or	a, d
	or	a, e
	or	a, b
	jr	Z, 00121$
	xor	a, a
	jp	00122$
00121$:
;ps_engine.c:417: moving = lev[i] & lmask;
	ld	l, c
;	spillPairReg hl
;	spillPairReg hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	add	hl, hl
	add	hl, hl
	ld	de, #_lev
	add	hl, de
	ex	de, hl
	push	de
	ld	hl, #8
	add	hl, sp
	ex	de, hl
	ld	bc, #0x0004
	ldir
	pop	hl
	ld	a, -9 (ix)
	and	a, -15 (ix)
	ld	c, a
	ld	a, -8 (ix)
	and	a, -14 (ix)
	ld	b, a
	ld	a, -7 (ix)
	and	a, -13 (ix)
	ld	e, a
	ld	a, -6 (ix)
	and	a, -12 (ix)
	ld	d, a
	ld	-5 (ix), c
	ld	-4 (ix), b
	ld	-3 (ix), e
	ld	-2 (ix), d
;ps_engine.c:418: lev[i] &= ~lmask;
	ld	a, -15 (ix)
	cpl
	ld	c, a
	ld	a, -14 (ix)
	cpl
	ld	b, a
	ld	a, -13 (ix)
	cpl
	ld	e, a
	ld	a, -12 (ix)
	cpl
	push	af
	ld	a, -9 (ix)
	and	a, c
	ld	c, a
	ld	a, -8 (ix)
	and	a, b
	ld	b, a
	ld	a, -7 (ix)
	and	a, e
	ld	e, a
	pop	af
	and	a, -6 (ix)
	ld	d, a
	ld	(hl), c
	inc	hl
	ld	(hl), b
	inc	hl
	ld	(hl), e
	inc	hl
	ld	(hl), d
;ps_engine.c:419: lev[ti] |= moving;
	ld	l, -11 (ix)
	ld	h, -10 (ix)
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
	inc	hl
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	ld	a, c
	or	a, -5 (ix)
	ld	c, a
	ld	a, b
	or	a, -4 (ix)
	ld	b, a
	ld	a, e
	or	a, -3 (ix)
	ld	e, a
	ld	a, d
	or	a, -2 (ix)
	ld	d, a
	ld	l, -11 (ix)
	ld	h, -10 (ix)
	ld	(hl), c
	inc	hl
	ld	(hl), b
	inc	hl
	ld	(hl), e
	inc	hl
	ld	(hl), d
;ps_engine.c:420: return 1;
	ld	a, #0x01
00122$:
;ps_engine.c:421: }
	ld	sp, ix
	pop	ix
	pop	hl
	pop	bc
	inc	sp
	jp	(hl)
;ps_engine.c:424: static void resolve_movements(void) {
;	---------------------------------
; Function resolve_movements
; ---------------------------------
_resolve_movements:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl, #-14
	add	hl, sp
	ld	sp, hl
;ps_engine.c:425: u8 moved = 1;
	ld	c, #0x01
;ps_engine.c:426: while (moved) {
00112$:
	ld	a, c
	or	a, a
	jp	Z, 00140$
;ps_engine.c:427: u8 x, y, i = 0, layer, sh;
	ld	e, #0x00
;ps_engine.c:428: moved = 0;
;ps_engine.c:429: for (x = 0; x < g_w; x++)
	ld	bc, #0x0
00121$:
	ld	hl, #_g_w
	ld	a, b
	sub	a, (hl)
	jr	NC, 00112$
;ps_engine.c:430: for (y = 0; y < g_h; y++, i++) {
	ld	d, #0x00
00119$:
	ld	hl, #_g_h
	ld	a, d
	sub	a, (hl)
	jp	NC, 00143$
;ps_engine.c:431: u32 m = mov[i];
	ld	l, e
;	spillPairReg hl
;	spillPairReg hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	add	hl, hl
	add	hl, hl
	ld	a, l
	add	a, #<(_mov)
	ld	-10 (ix), a
	ld	a, h
	adc	a, #>(_mov)
	ld	-9 (ix), a
	push	de
	push	bc
	ld	e, -10 (ix)
	ld	d, -9 (ix)
	ld	hl, #13
	add	hl, sp
	ex	de, hl
	ld	bc, #0x0004
	ldir
	pop	bc
	pop	de
;ps_engine.c:432: if (!m) continue;
	ld	a, -2 (ix)
	or	a, -3 (ix)
	or	a, -4 (ix)
	or	a, -5 (ix)
	jp	Z, 00109$
;ps_engine.c:433: for (layer = 0, sh = 0; layer < g_nlayers; layer++, sh += 5) {
	ld	-8 (ix), #0x00
	ld	-1 (ix), #0x00
00117$:
	ld	hl, #_g_nlayers
	ld	a, -1 (ix)
	sub	a, (hl)
	jp	NC, 00108$
;ps_engine.c:434: u8 lm = (u8)((m >> sh) & 0x1F);
	ld	a, -8 (ix)
	push	af
	ld	a, -5 (ix)
	ld	-14 (ix), a
	ld	a, -4 (ix)
	ld	-13 (ix), a
	ld	a, -3 (ix)
	ld	-12 (ix), a
	ld	a, -2 (ix)
	ld	-11 (ix), a
	pop	af
	inc	a
	jr	00197$
00196$:
	srl	-11 (ix)
	rr	-12 (ix)
	rr	-13 (ix)
	rr	-14 (ix)
00197$:
	dec	a
	jr	NZ, 00196$
	ld	a, -14 (ix)
	and	a, #0x1f
	ld	-7 (ix), a
	ld	-6 (ix), a
;ps_engine.c:435: if (!lm) continue;
	ld	a, -7 (ix)
	or	a, a
	jr	Z, 00107$
;ps_engine.c:436: if (reposition(i, x, y, layer, lm)) {
	push	bc
	push	de
	ld	h, -6 (ix)
	ld	l, -1 (ix)
	push	hl
	push	de
	inc	sp
	ld	l, b
;	spillPairReg hl
;	spillPairReg hl
	ld	a, e
	call	_reposition
	pop	de
	pop	bc
	or	a, a
	jr	Z, 00107$
;ps_engine.c:437: m &= ~((u32)0x1F << sh);
	ld	a, -8 (ix)
	ld	-14 (ix), #0x1f
	ld	-13 (ix), #0x00
	ld	-12 (ix), #0x00
	ld	-11 (ix), #0x00
	inc	a
	jr	00199$
00198$:
	sla	-14 (ix)
	rl	-13 (ix)
	rl	-12 (ix)
	rl	-11 (ix)
00199$:
	dec	a
	jr	NZ,00198$
	ld	a, -14 (ix)
	cpl
	push	af
	ld	a, -13 (ix)
	cpl
	ld	c, a
	ld	a, -12 (ix)
	cpl
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	ld	a, -11 (ix)
	cpl
	ld	h, a
;	spillPairReg hl
;	spillPairReg hl
	pop	af
	and	a, -5 (ix)
	ld	-5 (ix), a
	ld	a, c
	and	a, -4 (ix)
	ld	-4 (ix), a
	ld	a, l
	and	a, -3 (ix)
	ld	-3 (ix), a
	ld	a, h
	and	a, -2 (ix)
	ld	-2 (ix), a
;ps_engine.c:438: moved = 1;
	ld	c, #0x01
00107$:
;ps_engine.c:433: for (layer = 0, sh = 0; layer < g_nlayers; layer++, sh += 5) {
	inc	-1 (ix)
	ld	a, -8 (ix)
	add	a, #0x05
	ld	-8 (ix), a
	jp	00117$
00108$:
;ps_engine.c:441: mov[i] = m;
	push	de
	push	bc
	ld	e, -10 (ix)
	ld	d, -9 (ix)
	ld	hl, #13
	add	hl, sp
	ld	bc, #0x0004
	ldir
	pop	bc
	pop	de
00109$:
;ps_engine.c:430: for (y = 0; y < g_h; y++, i++) {
	inc	d
	inc	e
	jp	00119$
00143$:
;ps_engine.c:429: for (x = 0; x < g_w; x++)
	inc	b
	jp	00121$
;ps_engine.c:444: { u8 i; for (i = 0; i < g_ncells; i++) mov[i] = 0; }
00140$:
	ld	bc, #_mov
	ld	e, #0x00
00124$:
	ld	hl, #_g_ncells
	ld	a, e
	sub	a, (hl)
	jr	NC, 00126$
	ld	l, e
;	spillPairReg hl
;	spillPairReg hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	add	hl, hl
	add	hl, hl
	add	hl, bc
	xor	a, a
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	e
	jr	00124$
00126$:
;ps_engine.c:445: }
	ld	sp, ix
	pop	ix
	ret
;ps_engine.c:448: static u8 check_win(void) {
;	---------------------------------
; Function check_win
; ---------------------------------
_check_win:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl, #-30
	add	hl, sp
	ld	sp, hl
;ps_engine.c:449: const u8 *p = far_resolve(g_far_win);
	ld	hl, #_g_far_win
	call	_far_resolve
;ps_engine.c:450: u8 n = *p++, w;
	ld	a, (de)
	ld	-22 (ix), a
	inc	de
	ld	-6 (ix), e
	ld	-5 (ix), d
;ps_engine.c:451: if (turn_cmd & CMD_WIN) return 1;
	ld	a, (_turn_cmd+0)
	bit	2, a
	jr	Z, 00102$
	ld	a, #0x01
	jp	00128$
00102$:
;ps_engine.c:452: if (!n) return 0;
	ld	a, -22 (ix)
	or	a,a
;ps_engine.c:453: for (w = 0; w < n; w++, p += 10) {
	jp	Z,00128$
	ld	-4 (ix), #0x00
	ld	a, -6 (ix)
	ld	-3 (ix), a
	ld	a, -5 (ix)
	ld	-2 (ix), a
00126$:
	ld	a, -4 (ix)
	sub	a, -22 (ix)
	jp	NC, 00121$
;ps_engine.c:454: u8 type = p[0], aggr = p[1], i, hit = 0;
	ld	l, -3 (ix)
	ld	h, -2 (ix)
	ld	a, (hl)
	ld	-21 (ix), a
	ld	a, -3 (ix)
	ld	-6 (ix), a
	ld	a, -2 (ix)
	ld	-5 (ix), a
	ld	l, -6 (ix)
	ld	h, -5 (ix)
	inc	hl
	ld	a, (hl)
	ld	-1 (ix), a
	ld	-20 (ix), #0x00
;ps_engine.c:455: u32 f1 = rd32(p + 2), f2 = rd32(p + 6);
	ld	a, -3 (ix)
	add	a, #0x02
	ld	-6 (ix), a
	ld	a, -2 (ix)
	adc	a, #0x00
	ld	-5 (ix), a
	ld	l, -6 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, -5 (ix)
;	spillPairReg hl
;	spillPairReg hl
	call	_rd32
	ld	-8 (ix), e
	ld	-7 (ix), d
	ld	-6 (ix), l
	ld	-5 (ix), h
	ld	hl, #11
	add	hl, sp
	ex	de, hl
	ld	hl, #22
	add	hl, sp
	ld	bc, #4
	ldir
	ld	a, -3 (ix)
	add	a, #0x06
	ld	-6 (ix), a
	ld	a, -2 (ix)
	adc	a, #0x00
	ld	-5 (ix), a
	ld	l, -6 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, -5 (ix)
;	spillPairReg hl
;	spillPairReg hl
	call	_rd32
	ld	-8 (ix), e
	ld	-7 (ix), d
	ld	-6 (ix), l
	ld	-5 (ix), h
	ld	hl, #15
	add	hl, sp
	ex	de, hl
	ld	hl, #22
	add	hl, sp
	ld	bc, #4
	ldir
;ps_engine.c:456: for (i = 0; i < g_ncells; i++) {
	ld	a, -1 (ix)
	and	a, #0x01
	ld	-11 (ix), a
	ld	-10 (ix), #0x00
	ld	a, -1 (ix)
	and	a, #0x02
	ld	-9 (ix), a
	ld	-8 (ix), #0x00
	ld	a, -21 (ix)
	sub	a, #0x02
	ld	a, #0x01
	jr	Z, 00216$
	xor	a, a
00216$:
	ld	-7 (ix), a
	ld	-1 (ix), #0x00
00123$:
	ld	hl, #_g_ncells
	ld	a, -1 (ix)
	sub	a, (hl)
	jp	NC, 00117$
;ps_engine.c:457: u32 c = lev[i];
	ld	a, -1 (ix)
	ld	-6 (ix), a
	ld	-5 (ix), #0x00
	ld	a, -6 (ix)
	ld	-24 (ix), a
	ld	a, -5 (ix)
	ld	-23 (ix), a
	ld	b, #0x02
00217$:
	sla	-24 (ix)
	rl	-23 (ix)
	djnz	00217$
	ld	a, #<(_lev)
	add	a, -24 (ix)
	ld	-6 (ix), a
	ld	a, #>(_lev)
	adc	a, -23 (ix)
	ld	-5 (ix), a
	ld	e, -6 (ix)
	ld	d, -5 (ix)
	ld	hl, #0
	add	hl, sp
	ex	de, hl
	ld	bc, #0x0004
	ldir
;ps_engine.c:458: u8 m1 = (aggr & 1) ? ((c & f1) == f1) : ((c & f1) != 0);
	ld	a, -30 (ix)
	and	a, -19 (ix)
	ld	-26 (ix), a
	ld	a, -29 (ix)
	and	a, -18 (ix)
	ld	-25 (ix), a
	ld	a, -28 (ix)
	and	a, -17 (ix)
	ld	-24 (ix), a
	ld	a, -27 (ix)
	and	a, -16 (ix)
	ld	-23 (ix), a
	ld	a, -10 (ix)
	or	a, -11 (ix)
	jr	Z, 00130$
	ld	a, -26 (ix)
	sub	a, -19 (ix)
	jr	NZ, 00218$
	ld	a, -25 (ix)
	sub	a, -18 (ix)
	jr	NZ, 00218$
	ld	a, -24 (ix)
	sub	a, -17 (ix)
	jr	NZ, 00218$
	ld	a, -23 (ix)
	sub	a, -16 (ix)
	ld	a, #0x01
	jr	Z, 00219$
00218$:
	xor	a, a
00219$:
	ld	-5 (ix), a
	jr	00131$
00130$:
	ld	a, -23 (ix)
	or	a, -24 (ix)
	or	a, -25 (ix)
	or	a, -26 (ix)
	sub	a,#0x01
	ld	a, #0x00
	rla
	xor	a, #0x01
	ld	-5 (ix), a
00131$:
	ld	a, -5 (ix)
	ld	-6 (ix), a
;ps_engine.c:459: u8 m2 = (aggr & 2) ? ((c & f2) == f2) : ((c & f2) != 0);
	ld	a, -30 (ix)
	and	a, -15 (ix)
	ld	-26 (ix), a
	ld	a, -29 (ix)
	and	a, -14 (ix)
	ld	-25 (ix), a
	ld	a, -28 (ix)
	and	a, -13 (ix)
	ld	-24 (ix), a
	ld	a, -27 (ix)
	and	a, -12 (ix)
	ld	-23 (ix), a
	ld	a, -8 (ix)
	or	a, -9 (ix)
	jr	Z, 00132$
	ld	a, -26 (ix)
	sub	a, -15 (ix)
	jr	NZ, 00220$
	ld	a, -25 (ix)
	sub	a, -14 (ix)
	jr	NZ, 00220$
	ld	a, -24 (ix)
	sub	a, -13 (ix)
	jr	NZ, 00220$
	ld	a, -23 (ix)
	sub	a, -12 (ix)
	ld	a, #0x01
	jr	Z, 00221$
00220$:
	xor	a, a
00221$:
	ld	-5 (ix), a
	jr	00133$
00132$:
	ld	a, -23 (ix)
	or	a, -24 (ix)
	or	a, -25 (ix)
	or	a, -26 (ix)
	sub	a,#0x01
	ld	a, #0x00
	rla
	ld	-5 (ix), a
	xor	a, #0x01
	ld	-5 (ix), a
00133$:
;ps_engine.c:460: if (type == 2) { if (m1 && !m2) return 0; }        /* ALL  */
	ld	a, -7 (ix)
	or	a, a
	jr	Z, 00115$
	ld	a, -6 (ix)
	or	a, a
	jr	Z, 00124$
	ld	a, -5 (ix)
	or	a,a
	jr	NZ, 00124$
	jr	00128$
00115$:
;ps_engine.c:461: else if (m1 && m2) { hit = 1; if (type == 0) return 0; else break; }
	ld	a, -6 (ix)
	or	a, a
	jr	Z, 00124$
	ld	a, -5 (ix)
	or	a, a
	jr	Z, 00124$
	ld	-20 (ix), #0x01
	ld	a, -21 (ix)
	or	a,a
	jr	NZ, 00117$
	jr	00128$
00124$:
;ps_engine.c:456: for (i = 0; i < g_ncells; i++) {
	inc	-1 (ix)
	jp	00123$
00117$:
;ps_engine.c:463: if (type == 1 && !hit) return 0;                       /* SOME */
	ld	a, -21 (ix)
	dec	a
	jr	NZ, 00127$
	ld	a, -20 (ix)
	or	a,a
	jr	Z, 00128$
00127$:
;ps_engine.c:453: for (w = 0; w < n; w++, p += 10) {
	inc	-4 (ix)
	ld	a, -3 (ix)
	add	a, #0x0a
	ld	-3 (ix), a
	jp	NC,00126$
	inc	-2 (ix)
	jp	00126$
00121$:
;ps_engine.c:465: return 1;
	ld	a, #0x01
00128$:
;ps_engine.c:466: }
	ld	sp, ix
	pop	ix
	ret
;ps_engine.c:469: static void player_bitset_record(void) {
;	---------------------------------
; Function player_bitset_record
; ---------------------------------
_player_bitset_record:
	push	ix
	ld	ix,#0
	add	ix,sp
	dec	sp
;ps_engine.c:471: for (i = 0; i < 24; i++) pre_player[i] = 0;
	ld	c, #0x00
00105$:
	ld	hl, #_pre_player
	ld	b, #0x00
	add	hl, bc
	ld	(hl), #0x00
	inc	c
	ld	a, c
	sub	a, #0x18
	jr	C, 00105$
;ps_engine.c:472: for (i = 0; i < g_ncells; i++)
	ld	-1 (ix), #0x00
00108$:
	ld	hl, #_g_ncells
	ld	a, -1 (ix)
	sub	a, (hl)
	jr	NC, 00110$
;ps_engine.c:473: if (lev[i] & g_playerMask) pre_player[i >> 3] |= 1 << (i & 7);
	ld	l, -1 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	add	hl, hl
	add	hl, hl
	ld	de, #_lev
	add	hl, de
	ld	a, (hl)
	inc	hl
	ld	b, (hl)
	inc	hl
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	ld	iy, #_g_playerMask
	and	a, 0 (iy)
	ld	c, a
	ld	a, b
	and	a, 1 (iy)
	ld	b, a
	ld	a, e
	and	a, 2 (iy)
	ld	e, a
	ld	a, d
	and	a, 3 (iy)
	or	a, e
	or	a, b
	or	a, c
	jr	Z, 00109$
	ld	c, -1 (ix)
	srl	c
	srl	c
	srl	c
	ld	hl, #_pre_player
	ld	b, #0x00
	add	hl, bc
	ld	c, (hl)
	ld	a, -1 (ix)
	and	a, #0x07
	ld	b, a
	ld	a, #0x01
	inc	b
	jr	00140$
00139$:
	add	a, a
00140$:
	djnz	00139$
	or	a, c
	ld	(hl), a
00109$:
;ps_engine.c:472: for (i = 0; i < g_ncells; i++)
	inc	-1 (ix)
	jr	00108$
00110$:
;ps_engine.c:474: }
	inc	sp
	pop	ix
	ret
;ps_engine.c:478: static u8 turn(s8 dir) {
;	---------------------------------
; Function turn
; ---------------------------------
_turn:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl, #-24
	add	hl, sp
	ld	sp, hl
	ld	-3 (ix), a
;ps_engine.c:479: u8 i, modified = 0;
	ld	-24 (ix), #0x00
;ps_engine.c:482: for (i = 0; i < g_ncells; i++) { bak[i] = lev[i]; mov[i] = 0; }
	ld	de, #_mov+0
	ld	-1 (ix), #0x00
00132$:
	ld	hl, #_g_ncells
	ld	a, -1 (ix)
	sub	a, (hl)
	jr	NC, 00101$
	ld	l, -1 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	add	hl, hl
	add	hl, hl
	ld	c, l
	ld	b, h
	ld	hl, #_bak
	add	hl, bc
	ld	-9 (ix), l
	ld	-8 (ix), h
	ld	hl, #_lev
	add	hl, bc
	push	de
	push	bc
	ex	de, hl
	ld	hl, #21
	add	hl, sp
	ex	de, hl
	ld	bc, #0x0004
	ldir
	ld	e, -9 (ix)
	ld	d, -8 (ix)
	ld	hl, #21
	add	hl, sp
	ld	bc, #0x0004
	ldir
	pop	bc
	pop	de
	ld	l, c
	ld	h, b
	add	hl, de
	xor	a, a
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	-1 (ix)
	jr	00132$
00101$:
;ps_engine.c:483: turn_cmd = 0; turn_msg = 0xFF;
	ld	hl, #_turn_cmd
	ld	(hl), #0x00
	ld	hl, #_turn_msg
	ld	(hl), #0xff
;ps_engine.c:485: if (dir >= 0) {
	ld	a, -3 (ix)
	rlca
	and	a,#0x01
	ld	c, a
	bit	0, c
	jp	NZ, 00110$
;ps_engine.c:486: u32 dm = dirmask_tab[(u8)dir];
	ld	a, -3 (ix)
	add	a, #<(_turn_dirmask_tab_65536_182)
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	ld	a, #0x00
	adc	a, #>(_turn_dirmask_tab_65536_182)
	ld	h, a
	ld	a, (hl)
	ld	-23 (ix), a
	xor	a, a
	ld	-22 (ix), a
	ld	-21 (ix), a
	ld	-20 (ix), a
;ps_engine.c:488: player_bitset_record();
	push	bc
	push	de
	call	_player_bitset_record
	pop	de
	pop	bc
;ps_engine.c:489: for (i = 0; i < g_ncells; i++) {
	ld	-2 (ix), #0x00
00138$:
	ld	hl, #_g_ncells
	ld	a, -2 (ix)
	sub	a, (hl)
	jp	NC, 00110$
;ps_engine.c:490: if (!(lev[i] & g_playerMask)) continue;
	ld	l, -2 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	add	hl, hl
	add	hl, hl
	ld	-19 (ix), l
	ld	-18 (ix), h
	ld	a, #<(_lev)
	add	a, -19 (ix)
	ld	-17 (ix), a
	ld	a, #>(_lev)
	adc	a, -18 (ix)
	ld	-16 (ix), a
	ld	l, -17 (ix)
	ld	h, -16 (ix)
	ld	b, (hl)
	inc	hl
	inc	hl
	ld	a, (hl)
	dec	hl
	ld	l, (hl)
;	spillPairReg hl
	ld	h, a
;	spillPairReg hl
;	spillPairReg hl
	push	af
	ld	a, b
	ld	iy, #_g_playerMask
	and	a, 0 (iy)
	ld	-7 (ix), a
	ld	a, l
	and	a, 1 (iy)
	ld	-6 (ix), a
	ld	a, h
	and	a, 2 (iy)
	ld	-5 (ix), a
	pop	af
	and	a, 3 (iy)
	ld	-4 (ix), a
	or	a, -5 (ix)
	or	a, -6 (ix)
	or	a, -7 (ix)
	jp	Z, 00107$
;ps_engine.c:491: for (layer = 0, sh = 0; layer < g_nlayers; layer++, sh += 5)
	ld	b, #0x00
	ld	-1 (ix), #0x00
00135$:
	ld	hl, #_g_nlayers
	ld	a, -1 (ix)
	sub	a, (hl)
	jp	NC, 00107$
;ps_engine.c:492: if (lev[i] & g_playerMask & g_layerMasks[layer])
	push	de
	push	bc
	ld	e, -17 (ix)
	ld	d, -16 (ix)
	ld	hl, #21
	add	hl, sp
	ex	de, hl
	ld	bc, #0x0004
	ldir
	pop	bc
	pop	de
	ld	a, -7 (ix)
	ld	iy, #_g_playerMask
	and	a, 0 (iy)
	ld	-15 (ix), a
	ld	a, -6 (ix)
	and	a, 1 (iy)
	ld	-14 (ix), a
	ld	a, -5 (ix)
	and	a, 2 (iy)
	ld	-13 (ix), a
	ld	a, -4 (ix)
	and	a, 3 (iy)
	ld	-12 (ix), a
	ld	l, -1 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	add	hl, hl
	add	hl, hl
	ld	a, #<(_g_layerMasks)
	add	a, l
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	ld	a, #>(_g_layerMasks)
	adc	a, h
	ld	h, a
;	spillPairReg hl
;	spillPairReg hl
	push	de
	push	bc
	ex	de, hl
	ld	hl, #17
	add	hl, sp
	ex	de, hl
	ld	bc, #0x0004
	ldir
	pop	bc
	pop	de
	ld	a, -15 (ix)
	and	a, -11 (ix)
	ld	-7 (ix), a
	ld	a, -14 (ix)
	and	a, -10 (ix)
	ld	-6 (ix), a
	ld	a, -13 (ix)
	and	a, -9 (ix)
	ld	-5 (ix), a
	ld	a, -12 (ix)
	and	a, -8 (ix)
	ld	-4 (ix), a
	or	a, -5 (ix)
	or	a, -6 (ix)
	or	a, -7 (ix)
	jp	Z, 00136$
;ps_engine.c:493: mov[i] |= dm << sh;
	ld	a, #<(_mov)
	add	a, -19 (ix)
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	ld	a, #>(_mov)
	adc	a, -18 (ix)
	ld	h, a
;	spillPairReg hl
;	spillPairReg hl
	push	hl
	push	de
	push	bc
	ex	de, hl
	ld	hl, #15
	add	hl, sp
	ex	de, hl
	ld	bc, #0x0004
	ldir
	pop	bc
	pop	de
	pop	hl
	push	bc
	ld	a, -23 (ix)
	ld	-11 (ix), a
	ld	a, -22 (ix)
	ld	-10 (ix), a
	ld	a, -21 (ix)
	ld	-9 (ix), a
	ld	a, -20 (ix)
	ld	-8 (ix), a
	pop	af
	inc	a
	jr	00294$
00293$:
	sla	-11 (ix)
	rl	-10 (ix)
	rl	-9 (ix)
	rl	-8 (ix)
00294$:
	dec	a
	jr	NZ,00293$
	ld	a, -15 (ix)
	or	a, -11 (ix)
	ld	-7 (ix), a
	ld	a, -14 (ix)
	or	a, -10 (ix)
	ld	-6 (ix), a
	ld	a, -13 (ix)
	or	a, -9 (ix)
	ld	-5 (ix), a
	ld	a, -12 (ix)
	or	a, -8 (ix)
	ld	-4 (ix), a
	push	de
	push	bc
	ex	de,hl
	ld	hl, #21
	add	hl, sp
	ld	bc, #0x0004
	ldir
	pop	bc
	pop	de
00136$:
;ps_engine.c:491: for (layer = 0, sh = 0; layer < g_nlayers; layer++, sh += 5)
	inc	-1 (ix)
	ld	a, b
	add	a, #0x05
	ld	b, a
	jp	00135$
00107$:
;ps_engine.c:489: for (i = 0; i < g_ncells; i++) {
	inc	-2 (ix)
	jp	00138$
00110$:
;ps_engine.c:497: apply_rules(g_far_rules);
	push	bc
	push	de
	ld	hl, #_g_far_rules
	call	_apply_rules
	call	_resolve_movements
	ld	hl, #_g_far_late
	call	_apply_rules
	pop	de
	pop	bc
;ps_engine.c:502: if (dir >= 0 && dir <= 3 && (g_flags & FLG_REQPLAYERMOVE)) {
	bit	0, c
	jp	NZ, 00118$
	ld	a, #0x03
	sub	a, -3 (ix)
	jp	PO, 00295$
	xor	a, #0x80
00295$:
	jp	M, 00118$
	ld	a, (_g_flags+0)
	bit	3, a
	jp	Z,00118$
;ps_engine.c:503: u8 somemoved = 0;
	ld	c, #0x00
;ps_engine.c:504: for (i = 0; i < g_ncells; i++)
	ld	-1 (ix), #0x00
00140$:
	ld	hl, #_g_ncells
	ld	a, -1 (ix)
	sub	a, (hl)
	jr	NC, 00114$
;ps_engine.c:505: if ((pre_player[i >> 3] & (1 << (i & 7))) &&
	ld	a, -1 (ix)
	rrca
	rrca
	rrca
	and	a, #0x1f
	add	a, #<(_pre_player)
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	ld	a, #0x00
	adc	a, #>(_pre_player)
	ld	h, a
	ld	a, (hl)
	push	af
	ld	a, -1 (ix)
	and	a, #0x07
	ld	b, a
	pop	af
	ld	hl, #0x0001
	inc	b
	jr	00298$
00297$:
	add	hl, hl
00298$:
	djnz	00297$
	ld	b, #0x00
	and	a, l
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	ld	a, b
	and	a, h
	or	a, l
	jr	Z, 00141$
;ps_engine.c:506: !(lev[i] & g_playerMask)) { somemoved = 1; break; }
	ld	l, -1 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	add	hl, hl
	add	hl, hl
	ld	a, l
	add	a, #<(_lev)
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	ld	a, h
	adc	a, #>(_lev)
	ld	h, a
;	spillPairReg hl
;	spillPairReg hl
	ld	a, (hl)
	inc	hl
	ld	b, (hl)
	inc	hl
	inc	hl
	push	af
	ld	a, (hl)
	dec	hl
	ld	l, (hl)
;	spillPairReg hl
	ld	h, a
;	spillPairReg hl
;	spillPairReg hl
	pop	af
	ld	iy, #_g_playerMask
	and	a, 0 (iy)
	push	af
	ld	a, b
	and	a, 1 (iy)
	ld	b, a
	ld	a, l
	and	a, 2 (iy)
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	ld	a, h
	and	a, 3 (iy)
	ld	h, a
;	spillPairReg hl
;	spillPairReg hl
	pop	af
	or	a, h
	or	a, l
	or	a, b
	jr	NZ, 00141$
	ld	c, #0x01
	jr	00114$
00141$:
;ps_engine.c:504: for (i = 0; i < g_ncells; i++)
	inc	-1 (ix)
	jr	00140$
00114$:
;ps_engine.c:507: if (!somemoved) turn_cmd |= CMD_CANCEL;
	ld	a, c
	or	a, a
	jr	NZ, 00118$
	ld	a, (_turn_cmd+0)
	or	a, #0x01
	ld	(_turn_cmd+0), a
00118$:
;ps_engine.c:510: if (turn_cmd & CMD_CANCEL) {
	ld	a, (_turn_cmd+0)
	ld	-1 (ix), a
	bit	0, -1 (ix)
	jr	Z, 00175$
;ps_engine.c:511: for (i = 0; i < g_ncells; i++) { lev[i] = bak[i]; mov[i] = 0; }
	ld	bc, #_bak
	ld	-1 (ix), #0x00
00143$:
	ld	hl, #_g_ncells
	ld	a, -1 (ix)
	sub	a, (hl)
	jr	NC, 00121$
	ld	l, -1 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	add	hl, hl
	add	hl, hl
	ld	-11 (ix), l
	ld	-10 (ix), h
	ld	a, #<(_lev)
	add	a, -11 (ix)
	ld	-9 (ix), a
	ld	a, #>(_lev)
	adc	a, -10 (ix)
	ld	-8 (ix), a
	ld	l, -11 (ix)
	ld	h, -10 (ix)
	add	hl, bc
	push	de
	push	bc
	ex	de, hl
	ld	hl, #21
	add	hl, sp
	ex	de, hl
	ld	bc, #0x0004
	ldir
	ld	e, -9 (ix)
	ld	d, -8 (ix)
	ld	hl, #21
	add	hl, sp
	ld	bc, #0x0004
	ldir
	pop	bc
	pop	de
	ld	l, -11 (ix)
	ld	h, -10 (ix)
	add	hl, de
	xor	a, a
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	-1 (ix)
	jr	00143$
00121$:
;ps_engine.c:512: return 0;
	xor	a, a
	jp	00151$
;ps_engine.c:514: for (i = 0; i < g_ncells; i++)
00175$:
	ld	bc, #_lev
	ld	e, #0x00
00146$:
	ld	hl, #_g_ncells
	ld	a, e
	sub	a, (hl)
	jr	NC, 00126$
;ps_engine.c:515: if (lev[i] != bak[i]) { modified = 1; break; }
	ld	l, e
;	spillPairReg hl
;	spillPairReg hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	add	hl, hl
	add	hl, hl
	ld	-5 (ix), l
	ld	-4 (ix), h
	add	hl, bc
	push	de
	push	bc
	ex	de, hl
	ld	hl, #17
	add	hl, sp
	ex	de, hl
	ld	bc, #0x0004
	ldir
	pop	bc
	pop	de
	ld	a, #<(_bak)
	add	a, -5 (ix)
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	ld	a, #>(_bak)
	adc	a, -4 (ix)
	ld	h, a
;	spillPairReg hl
;	spillPairReg hl
	push	de
	push	bc
	ex	de, hl
	ld	hl, #21
	add	hl, sp
	ex	de, hl
	ld	bc, #0x0004
	ldir
	pop	bc
	pop	de
	ld	a, -11 (ix)
	sub	a, -7 (ix)
	jr	NZ, 00300$
	ld	a, -10 (ix)
	sub	a, -6 (ix)
	jr	NZ, 00300$
	ld	a, -9 (ix)
	sub	a, -5 (ix)
	jr	NZ, 00300$
	ld	a, -8 (ix)
	sub	a, -4 (ix)
	jr	Z, 00147$
00300$:
	ld	-24 (ix), #0x01
	jr	00126$
00147$:
;ps_engine.c:514: for (i = 0; i < g_ncells; i++)
	inc	e
	jr	00146$
00126$:
;ps_engine.c:516: if ((turn_cmd & CMD_CHECKPOINT) && modified)
	bit	4, -1 (ix)
	jr	Z, 00129$
	ld	a, -24 (ix)
	or	a, a
	jr	Z, 00129$
;ps_engine.c:517: for (i = 0; i < g_ncells; i++) chkpt[i] = lev[i];
	ld	-1 (ix), #0x00
00149$:
	ld	hl, #_g_ncells
	ld	a, -1 (ix)
	sub	a, (hl)
	jr	NC, 00129$
	ld	l, -1 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	add	hl, hl
	add	hl, hl
	ld	c, l
	ld	b, h
	ld	hl, #_chkpt
	add	hl, bc
	ex	de, hl
	ld	hl, #_lev
	add	hl, bc
	ex	de, hl
	push	hl
	ld	hl, #19
	add	hl, sp
	ex	de, hl
	ld	bc, #0x0004
	ldir
	pop	de
	ld	hl, #17
	add	hl, sp
	ld	bc, #0x0004
	ldir
	inc	-1 (ix)
	jr	00149$
00129$:
;ps_engine.c:518: return modified;
	ld	a, -24 (ix)
00151$:
;ps_engine.c:519: }
	ld	sp, ix
	pop	ix
	ret
_turn_dirmask_tab_65536_182:
	.db #0x01	; 1
	.db #0x04	; 4
	.db #0x02	; 2
	.db #0x08	; 8
	.db #0x10	; 16
;ps_engine.c:522: static void undo_push(const u32 *snapshot) {
;	---------------------------------
; Function undo_push
; ---------------------------------
_undo_push:
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
	push	af
	dec	sp
	ld	c, l
	ld	b, h
;ps_engine.c:524: if (g_flags & FLG_NOUNDO) return;
	ld	a, (_g_flags+0)
	bit	1, a
;ps_engine.c:525: for (i = 0; i < g_ncells; i++) undo_buf[undo_head][i] = snapshot[i];
	jr	NZ, 00109$
	ld	-1 (ix), #0x00
00107$:
	ld	hl, #_g_ncells
	ld	a, -1 (ix)
	sub	a, (hl)
	jr	NC, 00103$
	ld	a, (_undo_head+0)
	ld	e, a
	ld	d, #0x00
	ld	l, e
	ld	h, d
	add	hl, hl
	add	hl, de
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	ex	de, hl
	ld	hl, #_undo_buf
	add	hl, de
	ex	de, hl
	ld	l, -1 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	add	hl, hl
	add	hl, hl
	ld	a, e
	add	a, l
	ld	e, a
	ld	a, d
	adc	a, h
	ld	d, a
	add	hl, bc
	push	de
	push	bc
	ex	de, hl
	ld	hl, #4
	add	hl, sp
	ex	de, hl
	ld	bc, #0x0004
	ldir
	pop	bc
	pop	de
	push	bc
	ld	hl, #2
	add	hl, sp
	ld	bc, #0x0004
	ldir
	pop	bc
	inc	-1 (ix)
	jr	00107$
00103$:
;ps_engine.c:526: undo_head = (undo_head + 1) % UNDO_DEPTH;
	ld	a, (_undo_head+0)
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	inc	hl
	ld	de, #0x0003
	call	__modsint
	ld	hl, #_undo_head
	ld	(hl), e
;ps_engine.c:527: if (undo_count < UNDO_DEPTH) undo_count++;
	ld	a, (_undo_count+0)
	sub	a, #0x03
	jr	NC, 00109$
	ld	hl, #_undo_count
	inc	(hl)
00109$:
;ps_engine.c:528: }
	ld	sp, ix
	pop	ix
	ret
;ps_engine.c:529: static u8 undo_pop(void) {
;	---------------------------------
; Function undo_pop
; ---------------------------------
_undo_pop:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl, #-5
	add	hl, sp
	ld	sp, hl
;ps_engine.c:531: if (!undo_count) return 0;
	ld	a, (_undo_count+0)
	or	a,a
	jr	Z, 00107$
;ps_engine.c:532: undo_head = (undo_head + UNDO_DEPTH - 1) % UNDO_DEPTH;
	ld	a, (_undo_head+0)
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	inc	hl
	inc	hl
	ld	de, #0x0003
	call	__modsint
	ld	hl, #_undo_head
	ld	(hl), e
;ps_engine.c:533: undo_count--;
	ld	hl, #_undo_count
	dec	(hl)
;ps_engine.c:534: for (i = 0; i < g_ncells; i++) { lev[i] = undo_buf[undo_head][i]; mov[i] = 0; }
	ld	-1 (ix), #0x00
00105$:
	ld	hl, #_g_ncells
	ld	a, -1 (ix)
	sub	a, (hl)
	jr	NC, 00103$
	ld	l, -1 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	add	hl, hl
	add	hl, hl
	ld	c, l
	ld	b, h
	ld	hl, #_lev
	add	hl, bc
	ex	de, hl
	ld	a, (_undo_head+0)
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	push	de
	ld	e, l
	ld	d, h
	add	hl, hl
	add	hl, de
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	ld	de, #_undo_buf
	add	hl, de
	pop	de
	add	hl, bc
	push	de
	push	bc
	ex	de, hl
	ld	hl, #4
	add	hl, sp
	ex	de, hl
	ld	bc, #0x0004
	ldir
	pop	bc
	pop	de
	push	bc
	ld	hl, #2
	add	hl, sp
	ld	bc, #0x0004
	ldir
	pop	bc
	ld	hl, #_mov
	add	hl, bc
	xor	a, a
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	-1 (ix)
	jr	00105$
00103$:
;ps_engine.c:535: return 1;
	ld	a, #0x01
00107$:
;ps_engine.c:536: }
	ld	sp, ix
	pop	ix
	ret
;ps_engine.c:541: static u8 level_fetch(u8 idx) {
;	---------------------------------
; Function level_fetch
; ---------------------------------
_level_fetch:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl, #-5
	add	hl, sp
	ld	sp, hl
	ld	c, a
;ps_engine.c:542: const u8 *ix = far_resolve(g_far_levels);
	push	bc
	ld	hl, #_g_far_levels
	call	_far_resolve
	pop	bc
;ps_engine.c:543: const u8 *e = ix + 1 + ((u16)idx << 2);       /* u8 count, 4-byte entries */
	inc	de
	ld	l, c
;	spillPairReg hl
;	spillPairReg hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	add	hl, hl
	add	hl, hl
	add	hl, de
;ps_engine.c:544: u8 type = e[0];
	ld	c, (hl)
;ps_engine.c:545: const u8 *p = far_resolve(e + 1);
	inc	hl
	push	bc
	call	_far_resolve
	pop	bc
;ps_engine.c:546: if (type == 1) { msg_ptr = p; return 1; }
	dec	c
	jr	NZ, 00102$
	ld	(_msg_ptr), de
	ld	a, #0x01
	jp	00107$
00102$:
;ps_engine.c:547: g_w = p[0]; g_h = p[1];
	ld	a, (de)
	ld	(_g_w+0), a
	ld	c, e
	ld	b, d
	inc	bc
	ld	a, (bc)
	ld	(_g_h+0), a
;ps_engine.c:548: g_ncells = (u8)(g_w * g_h);
	push	de
	ld	a, (#_g_h + 0)
	ld	e, a
	ld	a, (#_g_w + 0)
	ld	h, a
;	spillPairReg hl
;	spillPairReg hl
	ld	l, #0x00
	ld	d, l
	ld	b, #0x08
00127$:
	add	hl, hl
	jr	NC, 00128$
	add	hl, de
00128$:
	djnz	00127$
	pop	de
	ld	a, l
	ld	(#_g_ncells), a
;ps_engine.c:550: u8 i; const u8 *c = p + 2;
	inc	de
	inc	de
;ps_engine.c:551: for (i = 0; i < g_ncells; i++, c += 4) {
	ld	-1 (ix), #0x00
00105$:
	ld	hl, #_g_ncells
	ld	a, -1 (ix)
	sub	a, (hl)
	jr	NC, 00103$
;ps_engine.c:552: lev[i] = rd32(c);
	ld	l, -1 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	add	hl, hl
	add	hl, hl
	ld	c, l
	ld	b, h
	ld	hl, #_lev
	add	hl, bc
	push	hl
	push	bc
;	spillPairReg hl
;	spillPairReg hl
	ex	de, hl
	push	hl
;	spillPairReg hl
;	spillPairReg hl
	call	_rd32
	ld	-5 (ix), e
	ld	-4 (ix), d
	ld	-3 (ix), l
	ld	-2 (ix), h
	pop	de
	pop	bc
	pop	hl
	push	de
	push	bc
	ex	de,hl
	ld	hl, #4
	add	hl, sp
	ld	bc, #0x0004
	ldir
	pop	bc
	pop	de
;ps_engine.c:553: chkpt[i] = lev[i];
	ld	hl, #_chkpt
	add	hl, bc
	push	de
	push	bc
	ex	de,hl
	ld	hl, #4
	add	hl, sp
	ld	bc, #0x0004
	ldir
	pop	bc
	pop	de
;ps_engine.c:554: mov[i] = 0;
	ld	hl, #_mov
	add	hl, bc
	xor	a, a
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	ld	(hl), a
;ps_engine.c:551: for (i = 0; i < g_ncells; i++, c += 4) {
	inc	-1 (ix)
	inc	de
	inc	de
	inc	de
	inc	de
	jr	00105$
00103$:
;ps_engine.c:557: undo_count = 0; undo_head = 0;
	ld	hl, #_undo_count
	ld	(hl), #0x00
	ld	hl, #_undo_head
	ld	(hl), #0x00
;ps_engine.c:558: return 0;
	xor	a, a
00107$:
;ps_engine.c:559: }
	ld	sp, ix
	pop	ix
	ret
;ps_engine.c:574: static void compose(u32 key) {
;	---------------------------------
; Function compose
; ---------------------------------
_compose:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	iy, #-14
	add	iy, sp
	ld	sp, iy
	ld	-10 (ix), e
	ld	-9 (ix), d
	ld	-8 (ix), l
	ld	-7 (ix), h
;ps_engine.c:575: const u8 *tiles = far_resolve(g_far_tiles);
	ld	hl, #_g_far_tiles
	call	_far_resolve
;ps_engine.c:577: for (row = 0; row < 128; row++) compose_buf[row] = 0;
	ld	c, #0x00
00108$:
	ld	hl, #_compose_buf
	ld	b, #0x00
	add	hl, bc
	ld	(hl), #0x00
	inc	c
	ld	a, c
	sub	a, #0x80
	jr	C, 00108$
;ps_engine.c:578: for (o = 0; o < g_nobj; o++) {
	ld	c, #0x00
00116$:
	ld	hl, #_g_nobj
	ld	a, c
	sub	a, (hl)
	jp	NC, 00117$
;ps_engine.c:579: u8 obj = g_drawOrder[o];
	ld	hl, #_g_drawOrder
	ld	b, #0x00
	add	hl, bc
	ld	a, (hl)
;ps_engine.c:582: if (!(key & ((u32)1 << obj))) continue;
	ld	-5 (ix), a
	ld	b, a
	ld	-14 (ix), #0x01
	xor	a, a
	ld	-13 (ix), a
	ld	-12 (ix), a
	ld	-11 (ix), a
	inc	b
	jr	00164$
00163$:
	sla	-14 (ix)
	rl	-13 (ix)
	rl	-12 (ix)
	rl	-11 (ix)
00164$:
	djnz	00163$
	ld	a, -10 (ix)
	and	a, -14 (ix)
	ld	-4 (ix), a
	ld	a, -9 (ix)
	and	a, -13 (ix)
	ld	-3 (ix), a
	ld	a, -8 (ix)
	and	a, -12 (ix)
	ld	-2 (ix), a
	ld	a, -7 (ix)
	and	a, -11 (ix)
	ld	-1 (ix), a
	or	a, -2 (ix)
	or	a, -3 (ix)
	or	a, -4 (ix)
	jp	Z, 00106$
;ps_engine.c:583: src = tiles + ((u16)obj * 160);
	ld	l, -5 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	push	de
	ld	e, l
	ld	d, h
	add	hl, hl
	add	hl, hl
	add	hl, de
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	pop	de
	add	hl, de
;ps_engine.c:584: dst = compose_buf;
	ld	-12 (ix), #<(_compose_buf)
	ld	-11 (ix), #>(_compose_buf)
;ps_engine.c:585: for (st = 0; st < 4; st++)
	ld	-6 (ix), #0x00
;ps_engine.c:586: for (row = 0; row < 8; row++) {
00123$:
	ld	-5 (ix), l
	ld	-4 (ix), h
	ld	a, -12 (ix)
	ld	-3 (ix), a
	ld	a, -11 (ix)
	ld	-2 (ix), a
	ld	-1 (ix), #0x08
00112$:
;ps_engine.c:587: u8 m = src[0], nm = (u8)~m;
	ld	l, -5 (ix)
	ld	h, -4 (ix)
	ld	b, (hl)
	ld	a, b
	cpl
	ld	-13 (ix), a
;ps_engine.c:588: dst[0] = (dst[0] & nm) | (src[1] & m);
	ld	l, -3 (ix)
	ld	h, -2 (ix)
	ld	a, (hl)
	and	a, -13 (ix)
	ld	l, -5 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, -4 (ix)
;	spillPairReg hl
;	spillPairReg hl
	inc	hl
	ld	l, (hl)
;	spillPairReg hl
	push	af
	ld	a, l
	and	a, b
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	pop	af
	or	a, l
	ld	l, -3 (ix)
	ld	h, -2 (ix)
	ld	(hl), a
;ps_engine.c:589: dst[1] = (dst[1] & nm) | (src[2] & m);
	ld	a, -3 (ix)
	add	a, #0x01
	ld	-12 (ix), a
	ld	a, -2 (ix)
	adc	a, #0x00
	ld	-11 (ix), a
	ld	l, -12 (ix)
	ld	h, -11 (ix)
	ld	a, (hl)
	and	a, -13 (ix)
	ld	l, -5 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, -4 (ix)
;	spillPairReg hl
;	spillPairReg hl
	inc	hl
	inc	hl
	ld	l, (hl)
;	spillPairReg hl
	push	af
	ld	a, l
	and	a, b
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	pop	af
	or	a, l
	ld	l, -12 (ix)
	ld	h, -11 (ix)
	ld	(hl), a
;ps_engine.c:590: dst[2] = (dst[2] & nm) | (src[3] & m);
	ld	a, -3 (ix)
	add	a, #0x02
	ld	-12 (ix), a
	ld	a, -2 (ix)
	adc	a, #0x00
	ld	-11 (ix), a
	ld	l, -12 (ix)
	ld	h, -11 (ix)
	ld	a, (hl)
	and	a, -13 (ix)
	ld	l, -5 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, -4 (ix)
;	spillPairReg hl
;	spillPairReg hl
	inc	hl
	inc	hl
	inc	hl
	ld	l, (hl)
;	spillPairReg hl
	push	af
	ld	a, l
	and	a, b
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	pop	af
	or	a, l
	ld	l, -12 (ix)
	ld	h, -11 (ix)
	ld	(hl), a
;ps_engine.c:591: dst[3] = (dst[3] & nm) | (src[4] & m);
	ld	a, -3 (ix)
	add	a, #0x03
	ld	-12 (ix), a
	ld	a, -2 (ix)
	adc	a, #0x00
	ld	-11 (ix), a
	ld	l, -12 (ix)
	ld	h, -11 (ix)
	ld	a, (hl)
	and	a, -13 (ix)
	ld	l, -5 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, -4 (ix)
;	spillPairReg hl
;	spillPairReg hl
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	ld	l, (hl)
;	spillPairReg hl
	push	af
	ld	a, l
	and	a, b
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	pop	af
	or	a, l
	ld	l, -12 (ix)
	ld	h, -11 (ix)
	ld	(hl), a
;ps_engine.c:592: src += 5; dst += 4;
	ld	a, -5 (ix)
	add	a, #0x05
	ld	-5 (ix), a
	jr	NC, 00165$
	inc	-4 (ix)
00165$:
	ld	a, -3 (ix)
	add	a, #0x04
	ld	-3 (ix), a
	jr	NC, 00166$
	inc	-2 (ix)
00166$:
	dec	-1 (ix)
;ps_engine.c:586: for (row = 0; row < 8; row++) {
	ld	a, -1 (ix)
	or	a, a
	jp	NZ, 00112$
;ps_engine.c:585: for (st = 0; st < 4; st++)
	ld	l, -5 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, -4 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	a, -3 (ix)
	ld	-12 (ix), a
	ld	a, -2 (ix)
	ld	-11 (ix), a
	inc	-6 (ix)
	ld	a, -6 (ix)
	sub	a, #0x04
	jp	C, 00123$
00106$:
;ps_engine.c:578: for (o = 0; o < g_nobj; o++) {
	inc	c
	jp	00116$
00117$:
;ps_engine.c:595: }
	ld	sp, ix
	pop	ix
	ret
;ps_engine.c:597: static u8 combo_get(u32 key) {          /* returns combo idx or 0xFE          */
;	---------------------------------
; Function combo_get
; ---------------------------------
_combo_get:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	iy, #-13
	add	iy, sp
	ld	sp, iy
	ld	-5 (ix), e
	ld	-4 (ix), d
	ld	-3 (ix), l
	ld	-2 (ix), h
;ps_engine.c:599: for (i = 0; i < combo_count; i++)
	ld	-6 (ix), #0x00
	ld	-1 (ix), #0x00
00112$:
	ld	hl, #_combo_count
	ld	a, -1 (ix)
	sub	a, (hl)
	jr	NC, 00103$
;ps_engine.c:600: if (combo_key[i] == key) return i;
	ld	l, -1 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	add	hl, hl
	add	hl, hl
	ld	de, #_combo_key
	add	hl, de
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
	inc	hl
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	ld	a, -5 (ix)
	sub	a, c
	jr	NZ, 00113$
	ld	a, -4 (ix)
	sub	a, b
	jr	NZ, 00113$
	ld	l, -3 (ix)
	ld	h, -2 (ix)
	cp	a, a
	sbc	hl, de
	jr	NZ, 00113$
	ld	a, -6 (ix)
	jp	00117$
00113$:
;ps_engine.c:599: for (i = 0; i < combo_count; i++)
	inc	-1 (ix)
	ld	a, -1 (ix)
	ld	-6 (ix), a
	jr	00112$
00103$:
;ps_engine.c:601: if (combo_count >= MAX_COMBOS) {
	ld	a, (_combo_count+0)
	sub	a, #0x57
	jp	C, 00110$
;ps_engine.c:604: for (o = (s8)g_nobj - 1; o >= 0; o--) {
	ld	a, (_g_nobj+0)
	ld	-1 (ix), a
	dec	-1 (ix)
00115$:
	bit	7, -1 (ix)
	jp	NZ, 00108$
;ps_engine.c:605: u32 single = (u32)1 << g_drawOrder[(u8)o];
	ld	a, -1 (ix)
	add	a, #<(_g_drawOrder)
	ld	-7 (ix), a
	ld	a, #0x00
	adc	a, #>(_g_drawOrder)
	ld	-6 (ix), a
	ld	l, -7 (ix)
	ld	h, -6 (ix)
	ld	a, (hl)
	ld	-6 (ix), a
	ld	b, a
	ld	-13 (ix), #0x01
	xor	a, a
	ld	-12 (ix), a
	ld	-11 (ix), a
	ld	-10 (ix), a
	inc	b
	jr	00162$
00161$:
	sla	-13 (ix)
	rl	-12 (ix)
	rl	-11 (ix)
	rl	-10 (ix)
00162$:
	djnz	00161$
;ps_engine.c:606: if (key & single) {
	ld	a, -5 (ix)
	and	a, -13 (ix)
	ld	-9 (ix), a
	ld	a, -4 (ix)
	and	a, -12 (ix)
	ld	-8 (ix), a
	ld	a, -3 (ix)
	and	a, -11 (ix)
	ld	-7 (ix), a
	ld	a, -2 (ix)
	and	a, -10 (ix)
	ld	-6 (ix), a
	or	a, -7 (ix)
	or	a, -8 (ix)
	or	a, -9 (ix)
	jr	Z, 00116$
;ps_engine.c:607: if (key == single) return 0xFE;   /* even singles overflow    */
	ld	a, -5 (ix)
	sub	a, -13 (ix)
	jr	NZ, 00105$
	ld	a, -4 (ix)
	sub	a, -12 (ix)
	jr	NZ, 00105$
	ld	a, -3 (ix)
	sub	a, -11 (ix)
	jr	NZ, 00105$
	ld	a, -2 (ix)
	sub	a, -10 (ix)
	jr	NZ, 00105$
	ld	a, #0xfe
	jr	00117$
00105$:
;ps_engine.c:608: return combo_get(single);
	pop	de
	push	de
	ld	l, -11 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, -10 (ix)
;	spillPairReg hl
;	spillPairReg hl
	call	_combo_get
	jr	00117$
00116$:
;ps_engine.c:604: for (o = (s8)g_nobj - 1; o >= 0; o--) {
	dec	-1 (ix)
	jp	00115$
00108$:
;ps_engine.c:611: return 0xFE;
	ld	a, #0xfe
	jr	00117$
00110$:
;ps_engine.c:613: compose(key);
	ld	e, -5 (ix)
	ld	d, -4 (ix)
	ld	l, -3 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, -2 (ix)
;	spillPairReg hl
;	spillPairReg hl
	call	_compose
;ps_engine.c:614: SMS_loadTiles(compose_buf, COMBO_BASE + ((u16)combo_count << 2), 128);
	ld	de, #_compose_buf+0
	ld	a, (_combo_count+0)
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	add	hl, hl
	add	hl, hl
	inc	hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	ld	bc, #0x0080
	push	bc
	call	_SMS_VRAMmemcpy
;ps_engine.c:615: combo_key[combo_count] = key;
	ld	a, (_combo_count+0)
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	ld	l, a
	add	hl, hl
	add	hl, hl
	ld	de, #_combo_key
	add	hl, de
	ex	de,hl
	ld	hl, #8
	add	hl, sp
	ld	bc, #0x0004
	ldir
;ps_engine.c:616: return combo_count++;
	ld	a, (_combo_count+0)
	ld	c, a
	ld	hl, #_combo_count
	inc	(hl)
	ld	a, c
00117$:
;ps_engine.c:617: }
	ld	sp, ix
	pop	ix
	ret
;ps_engine.c:619: static void draw_cell(u8 i, u8 x, u8 y) {
;	---------------------------------
; Function draw_cell
; ---------------------------------
_draw_cell:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	iy, #-10
	add	iy, sp
	ld	sp, iy
	ld	-1 (ix), a
	ld	-2 (ix), l
;ps_engine.c:620: u32 key = lev[i] & g_allMask;
	ld	bc, #_lev+0
	ld	l, -1 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	add	hl, hl
	add	hl, hl
	add	hl, bc
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
	inc	hl
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	ld	a, c
	ld	iy, #_g_allMask
	and	a, 0 (iy)
	ld	c, a
	ld	a, b
	and	a, 1 (iy)
	ld	b, a
	ld	a, e
	and	a, 2 (iy)
	ld	e, a
	ld	a, d
	and	a, 3 (iy)
	ld	d, a
	ld	-6 (ix), c
	ld	-5 (ix), b
	ld	-4 (ix), e
	ld	-3 (ix), d
;ps_engine.c:621: u8 ci = key ? combo_get(key) : 0xFE;
	ld	a, d
	or	a, e
	or	a, b
	or	a, c
	jr	Z, 00131$
	ld	e, -6 (ix)
	ld	d, -5 (ix)
	ld	l, -4 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, -3 (ix)
;	spillPairReg hl
;	spillPairReg hl
	call	_combo_get
	ld	c, a
	ld	b, #0x00
	jr	00132$
00131$:
	ld	bc, #0x00fe
00132$:
;ps_engine.c:624: if (cell_combo[i] == ci) return;
	ld	de, #_cell_combo+0
	ld	a, -1 (ix)
	add	a, e
	ld	e, a
	ld	a, #0x00
	adc	a, d
	ld	d, a
	ld	a, (de)
	sub	a, c
	jp	Z,00129$
	jr	00102$
00102$:
;ps_engine.c:625: cell_combo[i] = ci;
	ld	a, c
	ld	(de), a
;ps_engine.c:626: tx = off_x + (x << 1); ty = off_y + (y << 1);
	ld	a, -2 (ix)
	add	a, a
	ld	b, a
	ld	a, (_off_x+0)
	add	a, b
	ld	b, a
	ld	a, 4 (ix)
	add	a, a
	ld	e, a
	ld	a, (_off_y+0)
	add	a, e
	ld	e, a
;ps_engine.c:628: SMS_setTileatXY(tx,     ty,     0);
	ld	l, e
;	spillPairReg hl
;	spillPairReg hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	ld	-4 (ix), b
	ld	-3 (ix), #0x00
;ps_engine.c:629: SMS_setTileatXY(tx + 1, ty,     0);
	ld	a, b
;ps_engine.c:630: SMS_setTileatXY(tx,     ty + 1, 0);
	ld	d, #0x00
;ps_engine.c:628: SMS_setTileatXY(tx,     ty,     0);
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	ex	(sp), hl
	ld	l, -4 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, -3 (ix)
;	spillPairReg hl
;	spillPairReg hl
;ps_engine.c:629: SMS_setTileatXY(tx + 1, ty,     0);
	inc	a
	ld	-3 (ix), a
;ps_engine.c:630: SMS_setTileatXY(tx,     ty + 1, 0);
	inc	de
	push	de
	pop	iy
;ps_engine.c:628: SMS_setTileatXY(tx,     ty,     0);
	ld	a, l
	add	a, -10 (ix)
	ld	e, a
	ld	a, h
	adc	a, -9 (ix)
	ld	d, a
;ps_engine.c:629: SMS_setTileatXY(tx + 1, ty,     0);
	ld	a, -3 (ix)
;ps_engine.c:630: SMS_setTileatXY(tx,     ty + 1, 0);
;ps_engine.c:628: SMS_setTileatXY(tx,     ty,     0);
	ex	de, hl
	add	hl, hl
	ex	de, hl
	ld	-4 (ix), e
	ld	-3 (ix), d
;ps_engine.c:629: SMS_setTileatXY(tx + 1, ty,     0);
	ld	b, #0x00
;ps_engine.c:630: SMS_setTileatXY(tx,     ty + 1, 0);
	push	iy
	pop	de
	ex	de, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
;ps_engine.c:628: SMS_setTileatXY(tx,     ty,     0);
	push	af
	ex	de, hl
	ld	a, -4 (ix)
	ld	-8 (ix), a
	ld	a, -3 (ix)
	or	a, #0x78
	ld	-7 (ix), a
	pop	af
;ps_engine.c:629: SMS_setTileatXY(tx + 1, ty,     0);
	ld	-6 (ix), a
	ld	-5 (ix), b
;ps_engine.c:630: SMS_setTileatXY(tx,     ty + 1, 0);
	add	hl, de
;ps_engine.c:629: SMS_setTileatXY(tx + 1, ty,     0);
	ld	a, -6 (ix)
	add	a, -10 (ix)
	ld	-4 (ix), a
	ld	a, -5 (ix)
	adc	a, -9 (ix)
	ld	-3 (ix), a
;ps_engine.c:630: SMS_setTileatXY(tx,     ty + 1, 0);
	add	hl, hl
;ps_engine.c:631: SMS_setTileatXY(tx + 1, ty + 1, 0);
	ld	a, -6 (ix)
	add	a, e
	ld	e, a
	ld	a, -5 (ix)
	adc	a, d
	ld	d, a
;ps_engine.c:629: SMS_setTileatXY(tx + 1, ty,     0);
	ld	b, -4 (ix)
	ld	a, -3 (ix)
	sla	b
	adc	a, a
;ps_engine.c:630: SMS_setTileatXY(tx,     ty + 1, 0);
	ld	-6 (ix), l
	push	af
	ld	a, h
	or	a, #0x78
	ld	-5 (ix), a
	pop	af
;ps_engine.c:631: SMS_setTileatXY(tx + 1, ty + 1, 0);
	ex	de, hl
	add	hl, hl
	ex	de, hl
;ps_engine.c:629: SMS_setTileatXY(tx + 1, ty,     0);
	ld	-4 (ix), b
	or	a, #0x78
	ld	-3 (ix), a
;ps_engine.c:631: SMS_setTileatXY(tx + 1, ty + 1, 0);
	ld	a, d
	or	a, #0x78
	ld	d, a
;ps_engine.c:627: if (ci == 0xFE) {
	ld	a, c
	sub	a, #0xfe
	jr	NZ, 00116$
;ps_engine.c:628: SMS_setTileatXY(tx,     ty,     0);
	ld	l, -8 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, -7 (ix)
;	spillPairReg hl
;	spillPairReg hl
	call	_SMS_crt0_RST08
	ld	hl, #0x0000
	call	_SMS_crt0_RST18
;ps_engine.c:629: SMS_setTileatXY(tx + 1, ty,     0);
	ld	l, -4 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, -3 (ix)
;	spillPairReg hl
;	spillPairReg hl
	call	_SMS_crt0_RST08
	ld	hl, #0x0000
	call	_SMS_crt0_RST18
;ps_engine.c:630: SMS_setTileatXY(tx,     ty + 1, 0);
	ld	l, -6 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, -5 (ix)
;	spillPairReg hl
;	spillPairReg hl
	call	_SMS_crt0_RST08
	ld	hl, #0x0000
	call	_SMS_crt0_RST18
;ps_engine.c:631: SMS_setTileatXY(tx + 1, ty + 1, 0);
	ex	de, hl
	call	_SMS_crt0_RST08
	ld	hl, #0x0000
	call	_SMS_crt0_RST18
;ps_engine.c:632: return;
	jr	00129$
00116$:
;ps_engine.c:634: base = COMBO_BASE + ((u16)ci << 2);
	ld	l, c
;	spillPairReg hl
;	spillPairReg hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	add	hl, hl
	add	hl, hl
	inc	hl
;ps_engine.c:635: SMS_setTileatXY(tx,     ty,     base);
	push	hl
	ld	l, -8 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, -7 (ix)
;	spillPairReg hl
;	spillPairReg hl
	call	_SMS_crt0_RST08
	pop	bc
	ld	l, c
;	spillPairReg hl
;	spillPairReg hl
	ld	h, b
;	spillPairReg hl
;	spillPairReg hl
	call	_SMS_crt0_RST18
;ps_engine.c:636: SMS_setTileatXY(tx + 1, ty,     base + 1);
	push	bc
	ld	l, -4 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, -3 (ix)
;	spillPairReg hl
;	spillPairReg hl
	call	_SMS_crt0_RST08
	pop	bc
	ld	l, c
;	spillPairReg hl
;	spillPairReg hl
	ld	h, b
;	spillPairReg hl
;	spillPairReg hl
	inc	hl
	call	_SMS_crt0_RST18
;ps_engine.c:637: SMS_setTileatXY(tx,     ty + 1, base + 2);
	push	bc
	ld	l, -6 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, -5 (ix)
;	spillPairReg hl
;	spillPairReg hl
	call	_SMS_crt0_RST08
	pop	bc
	ld	l, c
;	spillPairReg hl
;	spillPairReg hl
	ld	h, b
;	spillPairReg hl
;	spillPairReg hl
	inc	hl
	inc	hl
	call	_SMS_crt0_RST18
;ps_engine.c:638: SMS_setTileatXY(tx + 1, ty + 1, base + 3);
	push	bc
	ex	de, hl
	call	_SMS_crt0_RST08
	pop	bc
	inc	bc
	inc	bc
	inc	bc
	ld	l, c
;	spillPairReg hl
;	spillPairReg hl
	ld	h, b
;	spillPairReg hl
;	spillPairReg hl
	call	_SMS_crt0_RST18
00129$:
;ps_engine.c:639: }
	ld	sp, ix
	pop	ix
	pop	hl
	inc	sp
	jp	(hl)
;ps_engine.c:641: static void draw_board(void) {          /* draws only stale cells             */
;	---------------------------------
; Function draw_board
; ---------------------------------
_draw_board:
;ps_engine.c:642: u8 x, y, i = 0;
;ps_engine.c:643: for (x = 0; x < g_w; x++)
	ld	bc, #0x0
00107$:
	ld	hl, #_g_w
	ld	a, b
	sub	a, (hl)
	ret	NC
;ps_engine.c:644: for (y = 0; y < g_h; y++, i++)
	ld	d, #0x00
00104$:
	ld	hl, #_g_h
	ld	a, d
	sub	a, (hl)
	jr	NC, 00115$
;ps_engine.c:645: draw_cell(i, x, y);
	push	bc
	push	de
	push	de
	inc	sp
	ld	l, b
;	spillPairReg hl
;	spillPairReg hl
	ld	a, c
	call	_draw_cell
	pop	de
	pop	bc
;ps_engine.c:644: for (y = 0; y < g_h; y++, i++)
	inc	d
	inc	c
	jr	00104$
00115$:
;ps_engine.c:643: for (x = 0; x < g_w; x++)
	inc	b
;ps_engine.c:646: }
	jr	00107$
;ps_engine.c:648: static void screen_clear(void) {
;	---------------------------------
; Function screen_clear
; ---------------------------------
_screen_clear:
;ps_engine.c:650: for (y = 0; y < 24; y++) {
	ld	b, #0x00
00105$:
;ps_engine.c:651: SMS_setNextTileatXY(0, y);
	ld	l, b
;	spillPairReg hl
;	spillPairReg hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	ld	a, h
	or	a, #0x78
	ld	h, a
;	spillPairReg hl
;	spillPairReg hl
	call	_SMS_crt0_RST08
;ps_engine.c:652: for (x = 0; x < 32; x++) SMS_setTile(0);
	ld	c, #0x00
00103$:
	ld	hl, #0x0000
	call	_SMS_crt0_RST18
	inc	c
	ld	a, c
	sub	a, #0x20
	jr	C, 00103$
;ps_engine.c:650: for (y = 0; y < 24; y++) {
	inc	b
	ld	a, b
	sub	a, #0x18
	jr	C, 00105$
;ps_engine.c:654: }
	ret
;ps_engine.c:656: static void board_reset_view(void) {
;	---------------------------------
; Function board_reset_view
; ---------------------------------
_board_reset_view:
;ps_engine.c:658: screen_clear();
	call	_screen_clear
;ps_engine.c:659: combo_count = 0;
	ld	hl, #_combo_count
;ps_engine.c:660: for (i = 0; i < g_ncells; i++) cell_combo[i] = 0xFF;
	ld	(hl), #0x00
	ld	c, (hl)
00103$:
	ld	hl, #_g_ncells
	ld	a, c
	sub	a, (hl)
	jr	NC, 00101$
	ld	hl, #_cell_combo
	ld	b, #0x00
	add	hl, bc
	ld	(hl), #0xff
	inc	c
	jr	00103$
00101$:
;ps_engine.c:661: off_x = (u8)((32 - (g_w << 1)) >> 1);
	ld	a, (_g_w+0)
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	ld	l, a
	add	hl, hl
	ld	a, #0x20
	sub	a, l
	ld	c, a
	sbc	a, a
	sub	a, h
	ld	b, a
	sra	b
	rr	c
	ld	hl, #_off_x
	ld	(hl), c
;ps_engine.c:662: off_y = (u8)((24 - (g_h << 1)) >> 1);
	ld	a, (_g_h+0)
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	ld	l, a
	add	hl, hl
	ld	a, #0x18
	sub	a, l
	ld	c, a
	sbc	a, a
	sub	a, h
	ld	b, a
	sra	b
	rr	c
	ld	iy, #_off_y
	ld	0 (iy), c
;ps_engine.c:663: draw_board();
;ps_engine.c:664: }
	jp	_draw_board
;ps_engine.c:667: static void draw_text(u8 x, u8 y, const char *s) {
;	---------------------------------
; Function draw_text
; ---------------------------------
_draw_text:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	c, a
;ps_engine.c:668: SMS_setNextTileatXY(x, y);
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	ld	b, #0x00
	add	hl, bc
	add	hl, hl
	ld	a, h
	or	a, #0x78
	ld	h, a
;	spillPairReg hl
;	spillPairReg hl
	call	_SMS_crt0_RST08
;ps_engine.c:669: while (*s) {
	ld	c, 4 (ix)
	ld	b, 5 (ix)
00104$:
	ld	a, (bc)
	or	a, a
	jr	Z, 00107$
;ps_engine.c:670: u8 c = (u8)*s++;
	inc	bc
;ps_engine.c:671: if (c < 32 || c > 127) c = '?';
	ld	e, a
	sub	a, #0x20
	jr	C, 00101$
	ld	a, #0x7f
	sub	a, e
	jr	NC, 00102$
00101$:
	ld	e, #0x3f
00102$:
;ps_engine.c:672: SMS_setTile(FONT_BASE + c - 32);
	ld	d, #0x00
	ld	hl, #0x0140
	add	hl, de
	call	_SMS_crt0_RST18
	jr	00104$
00107$:
;ps_engine.c:674: }
	pop	ix
	pop	hl
	pop	af
	jp	(hl)
;ps_engine.c:675: static u8 str_len(const char *s) { u8 n = 0; while (s[n]) n++; return n; }
;	---------------------------------
; Function str_len
; ---------------------------------
_str_len:
	ex	de, hl
	ld	c, #0x00
00101$:
	ld	l, c
	ld	h, #0x00
	add	hl, de
	ld	a, (hl)
	or	a, a
	jr	Z, 00103$
	inc	c
	jr	00101$
00103$:
	ld	a, c
	ret
;ps_engine.c:676: static void draw_text_centered(u8 y, const char *s) {
;	---------------------------------
; Function draw_text_centered
; ---------------------------------
_draw_text_centered:
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
;ps_engine.c:677: u8 n = str_len(s);
;	spillPairReg hl
;	spillPairReg hl
	ex	de, hl
	push	de
	push	hl
;	spillPairReg hl
;	spillPairReg hl
	call	_str_len
	pop	de
	pop	hl
	ld	c, a
;ps_engine.c:678: if (n > 32) n = 32;
	ld	a, #0x20
	sub	a, c
	jr	NC, 00102$
	ld	c, #0x20
00102$:
;ps_engine.c:679: draw_text((u8)((32 - n) >> 1), y, s);
	ld	b, #0x00
	ld	a, #0x20
	sub	a, c
	ld	c, a
	sbc	a, a
	sub	a, b
	ld	b, a
	sra	b
	rr	c
	push	de
	ld	a, c
	call	_draw_text
;ps_engine.c:680: }
	ret
;ps_engine.c:684: static void show_message(const u8 *text) {
;	---------------------------------
; Function show_message
; ---------------------------------
_show_message:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	iy, #-36
	add	iy, sp
	ld	sp, iy
	ld	-4 (ix), l
	ld	-3 (ix), h
;ps_engine.c:686: u8 y = 8;
	ld	-5 (ix), #0x08
;ps_engine.c:687: screen_clear();
	call	_screen_clear
;ps_engine.c:688: while (*text && y < 20) {
00116$:
	ld	l, -4 (ix)
	ld	h, -3 (ix)
	ld	a, (hl)
	or	a, a
	jp	Z, 00118$
	ld	a, -5 (ix)
	sub	a, #0x14
	jp	NC, 00118$
;ps_engine.c:689: u8 n = 0, last_sp = 0xFF;
	ld	-1 (ix), #0xff
;ps_engine.c:690: while (text[n] && n < 30) {
	ld	c, #0x00
00104$:
	ld	l, -4 (ix)
	ld	h, -3 (ix)
	ld	b, #0x00
	add	hl, bc
	ld	e, (hl)
	ld	a, c
	sub	a, #0x1e
	ld	a, #0x00
	rla
	ld	b, a
	ld	a, e
	or	a, a
	jr	Z, 00138$
	ld	a, b
	or	a, a
	jr	Z, 00138$
;ps_engine.c:691: if (text[n] == ' ') last_sp = n;
	ld	a, e
	sub	a, #0x20
	jr	NZ, 00102$
	ld	-1 (ix), c
00102$:
;ps_engine.c:692: n++;
	inc	c
	jr	00104$
00138$:
;ps_engine.c:694: if (text[n] && last_sp != 0xFF && n >= 30) n = last_sp;
	ld	a, e
	or	a, a
	jr	Z, 00134$
	ld	a, -1 (ix)
	inc	a
	jr	Z, 00134$
	bit	0, b
	jr	NZ, 00134$
	ld	c, -1 (ix)
;ps_engine.c:695: { u8 k; for (k = 0; k < n; k++) line[k] = (char)text[k]; line[n] = 0; }
00134$:
	ld	b, #0x00
00120$:
	ld	a, b
	sub	a, c
	jr	NC, 00111$
	ld	e, b
	ld	d, #0x00
	ld	hl, #0
	add	hl, sp
	add	hl, de
	ld	a, -4 (ix)
	add	a, b
	ld	e, a
	ld	a, -3 (ix)
	adc	a, #0x00
	ld	d, a
	ld	a, (de)
	ld	(hl), a
	inc	b
	jr	00120$
00111$:
	ld	e, c
	ld	d, #0x00
	ld	hl, #0
	add	hl, sp
	add	hl, de
	ld	(hl), #0x00
;ps_engine.c:696: draw_text_centered(y, line);
	push	bc
	ld	hl, #2
	add	hl, sp
	ex	de, hl
	ld	a, -5 (ix)
	call	_draw_text_centered
	pop	bc
;ps_engine.c:697: y += 2;
	ld	a, -5 (ix)
	add	a, #0x02
	ld	-5 (ix), a
;ps_engine.c:698: text += n;
	ld	a, c
	add	a, -4 (ix)
	ld	-4 (ix), a
	ld	a, #0x00
	adc	a, -3 (ix)
	ld	-3 (ix), a
;ps_engine.c:699: while (*text == ' ') text++;
	ld	a, -4 (ix)
	ld	-2 (ix), a
	ld	a, -3 (ix)
	ld	-1 (ix), a
00112$:
	ld	l, -2 (ix)
	ld	h, -1 (ix)
	ld	a, (hl)
	sub	a, #0x20
	jp	NZ,00116$
	inc	-2 (ix)
	jr	NZ, 00201$
	inc	-1 (ix)
00201$:
	ld	a, -2 (ix)
	ld	-4 (ix), a
	ld	a, -1 (ix)
	ld	-3 (ix), a
	jr	00112$
00118$:
;ps_engine.c:701: draw_text_centered(21, "PRESS 1");
	ld	de, #___str_0
	ld	a, #0x15
	call	_draw_text_centered
;ps_engine.c:702: wait_button1();
	call	_wait_button1
;ps_engine.c:703: }
	ld	sp, ix
	pop	ix
	ret
___str_0:
	.ascii "PRESS 1"
	.db 0x00
;ps_engine.c:707: static void frame_wait(void) { SMS_waitForVBlank(); frame_count++; }
;	---------------------------------
; Function frame_wait
; ---------------------------------
_frame_wait:
	call	_SMS_waitForVBlank
	ld	hl, #_frame_count
	inc	(hl)
	ret
;ps_engine.c:709: static void wait_button1(void) {
;	---------------------------------
; Function wait_button1
; ---------------------------------
_wait_button1:
00104$:
;ps_engine.c:711: frame_wait();
	call	_frame_wait
;ps_engine.c:712: if (SMS_getKeysPressed() & PORT_A_KEY_1) return;
	call	_SMS_getKeysPressed
	bit	4, e
	jr	Z, 00104$
;ps_engine.c:714: }
	ret
;ps_engine.c:720: static u8 poll_input(void) {
;	---------------------------------
; Function poll_input
; ---------------------------------
_poll_input:
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
;ps_engine.c:722: u16 ks = SMS_getKeysStatus();
	call	_SMS_getKeysStatus
	ld	c, e
	ld	b, d
;ps_engine.c:723: u16 pressed = ks & ~held_prev;
	ld	a, (_poll_input_held_prev_65536_270+0)
	cpl
	push	af
	ld	a, (_poll_input_held_prev_65536_270+1)
	cpl
	ld	d, a
	pop	af
	and	a, c
	ld	e, a
	ld	a, d
	and	a, b
	ld	d, a
;ps_engine.c:724: u8 r = 0xFF;
	ld	-2 (ix), #0xff
;ps_engine.c:728: if (hold2 == 60 && !(g_flags & FLG_NORESTART)) { held_prev = ks; return 6; }
	ld	a, (_g_flags+0)
	ld	-1 (ix), a
;ps_engine.c:726: if (ks & PORT_A_KEY_2) {
	bit	5, c
	jr	Z, 00108$
;ps_engine.c:727: hold2++;
	ld	iy, #_poll_input_hold2_65536_270
	inc	0 (iy)
;ps_engine.c:728: if (hold2 == 60 && !(g_flags & FLG_NORESTART)) { held_prev = ks; return 6; }
	ld	a, (_poll_input_hold2_65536_270+0)
	sub	a, #0x3c
	jr	NZ, 00109$
	bit	2, -1 (ix)
	jr	NZ, 00109$
	ld	(_poll_input_held_prev_65536_270), bc
	ld	a, #0x06
	jp	00144$
00108$:
;ps_engine.c:730: if (hold2 && hold2 < 60) { held_prev = ks; hold2 = 0; return 5; }
	ld	a, (_poll_input_hold2_65536_270+0)
	or	a, a
	jr	Z, 00105$
	ld	a, (_poll_input_hold2_65536_270+0)
	sub	a, #0x3c
	jr	NC, 00105$
	ld	(_poll_input_held_prev_65536_270), bc
	ld	hl, #_poll_input_hold2_65536_270
	ld	(hl), #0x00
	ld	a, #0x05
	jp	00144$
00105$:
;ps_engine.c:731: hold2 = 0;
	xor	a, a
	ld	(#_poll_input_hold2_65536_270), a
00109$:
;ps_engine.c:734: if (pressed & PORT_A_KEY_UP) r = 0;
	bit	0, e
	jr	Z, 00123$
	ld	-2 (ix), #0x00
	jr	00124$
00123$:
;ps_engine.c:735: else if (pressed & PORT_A_KEY_LEFT) r = 1;
	bit	2, e
	jr	Z, 00120$
	ld	-2 (ix), #0x01
	jr	00124$
00120$:
;ps_engine.c:736: else if (pressed & PORT_A_KEY_DOWN) r = 2;
	bit	1, e
	jr	Z, 00117$
	ld	-2 (ix), #0x02
	jr	00124$
00117$:
;ps_engine.c:737: else if (pressed & PORT_A_KEY_RIGHT) r = 3;
	bit	3, e
	jr	Z, 00114$
	ld	-2 (ix), #0x03
	jr	00124$
00114$:
;ps_engine.c:738: else if ((pressed & PORT_A_KEY_1) && !(g_flags & FLG_NOACTION)) r = 4;
	bit	4, e
	jr	Z, 00124$
	bit	4, -1 (ix)
	jr	NZ, 00124$
	ld	-2 (ix), #0x04
00124$:
;ps_engine.c:740: if (r != 0xFF) rep_timer = REPEAT_DELAY;
	ld	a, -2 (ix)
	inc	a
	jr	Z, 00142$
	ld	a, #0x12
	ld	(#_poll_input_rep_timer_65536_270), a
	jr	00143$
00142$:
;ps_engine.c:741: else if (ks & (PORT_A_KEY_UP | PORT_A_KEY_DOWN | PORT_A_KEY_LEFT | PORT_A_KEY_RIGHT)) {
	ld	a, c
	and	a, #0x0f
	jr	Z, 00143$
;ps_engine.c:742: if (rep_timer) rep_timer--;
	ld	a, (_poll_input_rep_timer_65536_270+0)
	or	a, a
	jr	Z, 00137$
	ld	iy, #_poll_input_rep_timer_65536_270
	dec	0 (iy)
	jr	00143$
00137$:
;ps_engine.c:744: rep_timer = REPEAT_RATE;
	ld	a, #0x07
	ld	(#_poll_input_rep_timer_65536_270), a
;ps_engine.c:745: if (ks & PORT_A_KEY_UP) r = 0;
	bit	0, c
	jr	Z, 00134$
	ld	-2 (ix), #0x00
	jr	00143$
00134$:
;ps_engine.c:746: else if (ks & PORT_A_KEY_LEFT) r = 1;
	bit	2, c
	jr	Z, 00131$
	ld	-2 (ix), #0x01
	jr	00143$
00131$:
;ps_engine.c:747: else if (ks & PORT_A_KEY_DOWN) r = 2;
	bit	1, c
	jr	Z, 00128$
	ld	-2 (ix), #0x02
	jr	00143$
00128$:
;ps_engine.c:748: else if (ks & PORT_A_KEY_RIGHT) r = 3;
	bit	3, c
	jr	Z, 00143$
	ld	-2 (ix), #0x03
00143$:
;ps_engine.c:751: held_prev = ks;
	ld	(_poll_input_held_prev_65536_270), bc
;ps_engine.c:752: rng_state ^= frame_count;             /* stir RNG with input timing       */
	ld	a, (_frame_count+0)
	ld	c, a
	ld	b, #0x00
	ld	a, (_rng_state+0)
	xor	a, c
	ld	(_rng_state+0), a
	ld	a, (_rng_state+1)
	xor	a, b
	ld	(_rng_state+1), a
;ps_engine.c:753: return r;
	ld	a, -2 (ix)
00144$:
;ps_engine.c:754: }
	ld	sp, ix
	pop	ix
	ret
;ps_engine.c:757: static void win_flash(void) {
;	---------------------------------
; Function win_flash
; ---------------------------------
_win_flash:
;ps_engine.c:759: for (f = 0; f < 3; f++) {
	ld	c, #0x00
;ps_engine.c:760: for (i = 0; i < 16; i++) SMS_setBGPaletteColor(i, 0x3F);
00109$:
	ld	b, #0x00
00103$:
	push	bc
	ld	l, #0x3f
;	spillPairReg hl
;	spillPairReg hl
	ld	a, b
	call	_SMS_setBGPaletteColor
	pop	bc
	inc	b
	ld	a, b
	sub	a, #0x10
	jr	C, 00103$
;ps_engine.c:761: frame_wait(); frame_wait(); frame_wait();
	push	bc
	call	_frame_wait
	call	_frame_wait
	call	_frame_wait
	ld	hl, #_g_palette
	call	_SMS_loadBGPalette
	call	_frame_wait
	call	_frame_wait
	call	_frame_wait
	pop	bc
;ps_engine.c:759: for (f = 0; f < 3; f++) {
	inc	c
	ld	a, c
	sub	a, #0x03
	jr	C, 00109$
;ps_engine.c:765: }
	ret
;ps_engine.c:767: static void title_screen(void) {
;	---------------------------------
; Function title_screen
; ---------------------------------
_title_screen:
;ps_engine.c:768: screen_clear();
	call	_screen_clear
;ps_engine.c:769: draw_text_centered(8, g_title);
	ld	de, #_g_title
	ld	a, #0x08
	call	_draw_text_centered
;ps_engine.c:770: if (g_author[0]) {
	ld	de, #_g_author+0
	ld	a, (de)
	or	a, a
	jr	Z, 00102$
;ps_engine.c:771: draw_text_centered(11, "BY");
	push	de
	ld	de, #___str_1
	ld	a, #0x0b
	call	_draw_text_centered
	pop	de
;ps_engine.c:772: draw_text_centered(12, g_author);
	ld	a, #0x0c
	call	_draw_text_centered
00102$:
;ps_engine.c:774: draw_text_centered(17, "PRESS 1 TO START");
	ld	de, #___str_2
	ld	a, #0x11
	call	_draw_text_centered
;ps_engine.c:775: draw_text_centered(20, "2:UNDO  HOLD 2:RESTART");
	ld	de, #___str_3
	ld	a, #0x14
	call	_draw_text_centered
;ps_engine.c:776: wait_button1();
;ps_engine.c:777: }
	jp	_wait_button1
___str_1:
	.ascii "BY"
	.db 0x00
___str_2:
	.ascii "PRESS 1 TO START"
	.db 0x00
___str_3:
	.ascii "2:UNDO  HOLD 2:RESTART"
	.db 0x00
;ps_engine.c:780: static u8 post_turn(u8 modified) {
;	---------------------------------
; Function post_turn
; ---------------------------------
_post_turn:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl, #-5
	add	hl, sp
	ld	sp, hl
	ld	c, a
;ps_engine.c:781: if (turn_cmd & CMD_RESTART) {
	ld	a, (_turn_cmd+0)
	bit	1, a
	jr	Z, 00103$
;ps_engine.c:783: undo_push(bak);
	ld	hl, #_bak
	call	_undo_push
;ps_engine.c:784: for (i = 0; i < g_ncells; i++) { lev[i] = chkpt[i]; mov[i] = 0; }
	ld	-1 (ix), #0x00
00126$:
	ld	hl, #_g_ncells
	ld	a, -1 (ix)
	sub	a, (hl)
	jr	NC, 00101$
	ld	l, -1 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	add	hl, hl
	add	hl, hl
	ld	c, l
	ld	b, h
	ld	hl, #_lev
	add	hl, bc
	ex	de, hl
	ld	hl, #_chkpt
	add	hl, bc
	push	de
	push	bc
	ex	de, hl
	ld	hl, #4
	add	hl, sp
	ex	de, hl
	ld	bc, #0x0004
	ldir
	pop	bc
	pop	de
	push	bc
	ld	hl, #2
	add	hl, sp
	ld	bc, #0x0004
	ldir
	pop	bc
	ld	hl, #_mov
	add	hl, bc
	xor	a, a
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	-1 (ix)
	jr	00126$
00101$:
;ps_engine.c:785: draw_board();
	call	_draw_board
;ps_engine.c:786: return 0;
	xor	a, a
	jp	00134$
00103$:
;ps_engine.c:788: if (modified) undo_push(bak);
	ld	a, c
	or	a, a
	jr	Z, 00105$
	push	bc
	ld	hl, #_bak
	call	_undo_push
	pop	bc
00105$:
;ps_engine.c:789: draw_board();
	push	bc
	call	_draw_board
	pop	bc
;ps_engine.c:791: if (turn_msg != 0xFF) {
	ld	a, (_turn_msg+0)
	inc	a
	jr	Z, 00108$
;ps_engine.c:792: const u8 *mi = far_resolve(g_far_msgs);
	push	bc
	ld	hl, #_g_far_msgs
	call	_far_resolve
	pop	bc
;ps_engine.c:793: const u8 *mp = far_resolve(mi + 1 + ((u16)turn_msg * 3));
	inc	de
	ld	a, (_turn_msg+0)
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	push	de
	ld	e, l
	ld	d, h
	add	hl, hl
	add	hl, de
	pop	de
	add	hl, de
	push	bc
	call	_far_resolve
	ex	de, hl
	call	_show_message
	call	_board_reset_view
	pop	bc
;ps_engine.c:797: for (i = 0; i < 60; i++) frame_wait();
	ld	b, #0x3c
00130$:
	push	bc
	call	_frame_wait
	pop	bc
	dec	b
	ld	a, b
	jr	NZ, 00130$
00108$:
;ps_engine.c:800: if (check_win()) { win_flash(); return 1; }
	push	bc
	call	_check_win
	pop	bc
	or	a, a
	jr	Z, 00110$
	call	_win_flash
	ld	a, #0x01
	jr	00134$
00110$:
;ps_engine.c:803: if ((turn_cmd & CMD_AGAIN) && modified) {
	ld	a, (_turn_cmd+0)
	bit	3, a
	jr	Z, 00123$
	ld	a, c
	or	a, a
	jr	Z, 00123$
;ps_engine.c:805: while (iter++ < 250) {
	ld	c, #0x00
00119$:
	ld	a, c
	sub	a, #0xfa
	jr	NC, 00123$
	inc	c
;ps_engine.c:807: for (f = 0; f < g_again_interval; f++) frame_wait();
	ld	b, #0x00
00132$:
	ld	hl, #_g_again_interval
	ld	a, b
	sub	a, (hl)
	jr	NC, 00111$
	push	bc
	call	_frame_wait
	pop	bc
	inc	b
	jr	00132$
00111$:
;ps_engine.c:808: m = turn(-1);
	push	bc
	ld	a, #0xff
	call	_turn
	pop	bc
	ld	b, a
;ps_engine.c:809: draw_board();
	push	bc
	call	_draw_board
	pop	bc
;ps_engine.c:810: if (turn_cmd & CMD_RESTART) return post_turn(m);
	ld	a, (_turn_cmd+0)
	bit	1, a
	jr	Z, 00113$
	ld	a, b
	call	_post_turn
	jr	00134$
00113$:
;ps_engine.c:811: if (check_win()) { win_flash(); return 1; }
	push	bc
	call	_check_win
	pop	bc
	or	a, a
	jr	Z, 00115$
	call	_win_flash
	ld	a, #0x01
	jr	00134$
00115$:
;ps_engine.c:812: if (!((turn_cmd & CMD_AGAIN) && m)) break;
	ld	a, (_turn_cmd+0)
	bit	3, a
	jr	Z, 00123$
	ld	a, b
	or	a, a
	jr	NZ, 00119$
00123$:
;ps_engine.c:815: return 0;
	xor	a, a
00134$:
;ps_engine.c:816: }
	ld	sp, ix
	pop	ix
	ret
;ps_engine.c:818: static void load_header(void) {
;	---------------------------------
; Function load_header
; ---------------------------------
_load_header:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl, #-7
	add	hl, sp
	ld	sp, hl
;ps_engine.c:819: const u8 *h = map_bank(0);
	xor	a, a
	call	_map_bank
;ps_engine.c:821: g_nobj  = h[H_NOBJ];  g_nlayers = h[H_NLAYERS];
	ld	c,e
	ld	b,d
	ld	hl, #5
	add	hl, de
	ld	a, (hl)
	ld	(_g_nobj+0), a
	ld	e, c
	ld	d, b
	ld	hl, #6
	add	hl, de
	ld	a, (hl)
	ld	(_g_nlayers+0), a
;ps_engine.c:822: g_nlevels = h[H_NLEVELS];
	ld	e, c
	ld	d, b
	ld	hl, #7
	add	hl, de
	ld	a, (hl)
	ld	(_g_nlevels+0), a
;ps_engine.c:823: g_playerMask = rd32(h + H_PLAYERMASK);
	ld	hl, #0x0008
	add	hl, bc
	push	bc
	call	_rd32
	pop	bc
	ld	(_g_playerMask), de
	ld	(_g_playerMask + 2), hl
;ps_engine.c:824: g_flags = h[H_FLAGS]; g_again_interval = h[H_AGAIN];
	ld	e, c
	ld	d, b
	ld	hl, #12
	add	hl, de
	ld	a, (hl)
	ld	(_g_flags+0), a
	ld	e, c
	ld	d, b
	ld	hl, #13
	add	hl, de
	ld	a, (hl)
	ld	(_g_again_interval+0), a
;ps_engine.c:825: g_textcol = h[H_TEXTCOL];
	ld	e, c
	ld	d, b
	ld	hl, #14
	add	hl, de
	ld	a, (hl)
	ld	(_g_textcol+0), a
;ps_engine.c:826: for (i = 0; i < MAX_LAYERS; i++) g_layerMasks[i] = rd32(h + H_LAYERMASKS + (i << 2));
	ld	hl, #0x0010
	add	hl, bc
	ex	de, hl
	ld	-1 (ix), #0x00
00106$:
	ld	l, -1 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	add	hl, hl
	add	hl, hl
	ld	a, #<(_g_layerMasks)
	add	a, l
	ld	-7 (ix), a
	ld	a, #>(_g_layerMasks)
	adc	a, h
	ld	-6 (ix), a
	add	hl, de
	push	bc
	push	de
	call	_rd32
	ld	-5 (ix), e
	ld	-4 (ix), d
	ld	-3 (ix), l
	ld	-2 (ix), h
	pop	de
	pop	bc
	push	de
	push	bc
	ld	e, -7 (ix)
	ld	d, -6 (ix)
	ld	hl, #6
	add	hl, sp
	ld	bc, #0x0004
	ldir
	pop	bc
	pop	de
	inc	-1 (ix)
	ld	a, -1 (ix)
	sub	a, #0x06
	jr	C, 00106$
;ps_engine.c:827: for (i = 0; i < MAX_OBJECTS; i++) {
	ld	-1 (ix), #0x00
00108$:
;ps_engine.c:828: g_objLayer[i]  = h[H_OBJLAYER + i];
	ld	a, #<(_g_objLayer)
	add	a, -1 (ix)
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	ld	a, #>(_g_objLayer)
	adc	a, #0x00
	ld	h, a
;	spillPairReg hl
;	spillPairReg hl
	ld	e, -1 (ix)
	ld	d, #0x00
	ld	iy, #0x0028
	add	iy, de
	add	iy, bc
	ld	a, 0 (iy)
	ld	(hl), a
;ps_engine.c:829: g_drawOrder[i] = h[H_DRAWORDER + i];
	ld	a, #<(_g_drawOrder)
	add	a, -1 (ix)
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	ld	a, #>(_g_drawOrder)
	adc	a, #0x00
	ld	h, a
;	spillPairReg hl
;	spillPairReg hl
	ld	iy, #0x0048
	add	iy, de
	add	iy, bc
	ld	a, 0 (iy)
	ld	(hl), a
;ps_engine.c:827: for (i = 0; i < MAX_OBJECTS; i++) {
	inc	-1 (ix)
	ld	a, -1 (ix)
	sub	a, #0x20
	jr	C, 00108$
;ps_engine.c:831: for (i = 0; i < 16; i++) g_palette[i] = h[H_PALETTE + i];
	ld	e, #0x00
00110$:
	ld	hl, #_g_palette
	ld	d, #0x00
	add	hl, de
	ld	a, e
	push	iy
	ex	(sp), hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	ex	(sp), hl
	pop	iy
	ld	iy, #0x0068
	push	bc
	ld	c, a
	ld	b, iyh
	add	iy, bc
	pop	bc
	add	iy, bc
	ld	a, 0 (iy)
	ld	(hl), a
	inc	e
	ld	a, e
	sub	a, #0x10
	jr	C, 00110$
;ps_engine.c:832: for (i = 0; i < 3; i++) {
	ld	-1 (ix), #0x00
00112$:
;ps_engine.c:833: g_far_tiles[i]  = h[H_TILES + i];
	ld	a, #<(_g_far_tiles)
	add	a, -1 (ix)
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	ld	a, #>(_g_far_tiles)
	adc	a, #0x00
	ld	h, a
;	spillPairReg hl
;	spillPairReg hl
	ld	e, -1 (ix)
	ld	d, #0x00
	ld	iy, #0x0078
	add	iy, de
	add	iy, bc
	ld	a, 0 (iy)
	ld	(hl), a
;ps_engine.c:834: g_far_levels[i] = h[H_LEVELS + i];
	ld	a, #<(_g_far_levels)
	add	a, -1 (ix)
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	ld	a, #>(_g_far_levels)
	adc	a, #0x00
	ld	h, a
;	spillPairReg hl
;	spillPairReg hl
	ld	iy, #0x007b
	add	iy, de
	add	iy, bc
	ld	a, 0 (iy)
	ld	(hl), a
;ps_engine.c:835: g_far_rules[i]  = h[H_RULES + i];
	ld	a, #<(_g_far_rules)
	add	a, -1 (ix)
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	ld	a, #>(_g_far_rules)
	adc	a, #0x00
	ld	h, a
;	spillPairReg hl
;	spillPairReg hl
	ld	iy, #0x007e
	add	iy, de
	add	iy, bc
	ld	a, 0 (iy)
	ld	(hl), a
;ps_engine.c:836: g_far_late[i]   = h[H_LATERULES + i];
	ld	a, #<(_g_far_late)
	add	a, -1 (ix)
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	ld	a, #>(_g_far_late)
	adc	a, #0x00
	ld	h, a
;	spillPairReg hl
;	spillPairReg hl
	ld	iy, #0x0081
	add	iy, de
	add	iy, bc
	ld	a, 0 (iy)
	ld	(hl), a
;ps_engine.c:837: g_far_win[i]    = h[H_WIN + i];
	ld	a, #<(_g_far_win)
	add	a, -1 (ix)
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	ld	a, #>(_g_far_win)
	adc	a, #0x00
	ld	h, a
;	spillPairReg hl
;	spillPairReg hl
	ld	iy, #0x0084
	add	iy, de
	add	iy, bc
	ld	a, 0 (iy)
	ld	(hl), a
;ps_engine.c:838: g_far_msgs[i]   = h[H_MESSAGES + i];
	ld	a, #<(_g_far_msgs)
	add	a, -1 (ix)
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	ld	a, #>(_g_far_msgs)
	adc	a, #0x00
	ld	h, a
;	spillPairReg hl
;	spillPairReg hl
	ld	iy, #0x0087
	add	iy, de
	add	iy, bc
	ld	a, 0 (iy)
	ld	(hl), a
;ps_engine.c:832: for (i = 0; i < 3; i++) {
	inc	-1 (ix)
	ld	a, -1 (ix)
	sub	a, #0x03
	jp	C, 00112$
;ps_engine.c:840: for (i = 0; i < 32; i++) { g_title[i] = (char)h[H_TITLE + i]; g_author[i] = (char)h[H_AUTHOR + i]; }
	ld	-1 (ix), #0x00
00114$:
	ld	a, #<(_g_title)
	add	a, -1 (ix)
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	ld	a, #>(_g_title)
	adc	a, #0x00
	ld	h, a
;	spillPairReg hl
;	spillPairReg hl
	ld	e, -1 (ix)
	ld	d, #0x00
	ld	iy, #0x008a
	add	iy, de
	add	iy, bc
	ld	a, 0 (iy)
	ld	(hl), a
	ld	a, #<(_g_author)
	add	a, -1 (ix)
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	ld	a, #>(_g_author)
	adc	a, #0x00
	ld	h, a
;	spillPairReg hl
;	spillPairReg hl
	ld	iy, #0x00aa
	add	iy, de
	add	iy, bc
	ld	a, 0 (iy)
	ld	(hl), a
	inc	-1 (ix)
	ld	a, -1 (ix)
	sub	a, #0x20
	jr	C, 00114$
;ps_engine.c:841: g_title[31] = 0; g_author[31] = 0;
	ld	hl, #(_g_title + 31)
	ld	(hl), #0x00
	ld	hl, #(_g_author + 31)
	ld	(hl), #0x00
;ps_engine.c:842: g_allMask = (g_nobj >= 32) ? 0xFFFFFFFFUL : (((u32)1 << g_nobj) - 1);
	ld	a, (_g_nobj+0)
	sub	a, #0x20
	jr	C, 00118$
	ld	-4 (ix), #0xff
	ld	-3 (ix), #0xff
	ld	-2 (ix), #0xff
	ld	-1 (ix), #0xff
	jr	00119$
00118$:
	ld	a, (_g_nobj+0)
	ld	e, a
	ld	hl, #0x0001
	ld	bc, #0x0000
	inc	e
	jr	00181$
00180$:
	add	hl, hl
	rl	c
	rl	b
00181$:
	dec	e
	jr	NZ,00180$
	ld	a, l
	add	a, #0xff
	ld	-4 (ix), a
	ld	a, h
	adc	a, #0xff
	ld	-3 (ix), a
	ld	a, c
	adc	a, #0xff
	ld	-2 (ix), a
	ld	a, b
	adc	a, #0xff
	ld	-1 (ix), a
00119$:
	ld	de, #_g_allMask
	ld	hl, #3
	add	hl, sp
	ld	bc, #4
	ldir
;ps_engine.c:843: }
	ld	sp, ix
	pop	ix
	ret
;ps_engine.c:845: void main(void) {
;	---------------------------------
; Function main
; ---------------------------------
_main::
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl, #-5
	add	hl, sp
	ld	sp, hl
;ps_engine.c:846: SMS_displayOff();
	ld	hl, #0x0140
	call	_SMS_VDPturnOffFeature
;ps_engine.c:847: load_header();
	call	_load_header
;ps_engine.c:848: SMS_loadBGPalette(g_palette);
	ld	hl, #_g_palette
	call	_SMS_loadBGPalette
;ps_engine.c:849: SMS_loadSpritePalette(g_palette);
	ld	hl, #_g_palette
	call	_SMS_loadSpritePalette
;ps_engine.c:850: SMS_setBackdropColor(0);
	ld	l, #0x00
;	spillPairReg hl
;	spillPairReg hl
	call	_SMS_setBackdropColor
;ps_engine.c:851: SMS_load1bppTiles(ps_font, FONT_BASE, 768, 0, g_textcol);
	ld	a, (_g_textcol+0)
	ld	h, a
	ld	l, #0x00
	push	hl
	ld	hl, #0x0300
	push	hl
	ld	de, #0x0160
	ld	hl, #_ps_font
	call	_SMS_load1bppTiles
;ps_engine.c:852: SMS_initSprites(); SMS_copySpritestoSAT();
	call	_SMS_initSprites
	call	_SMS_copySpritestoSAT
;ps_engine.c:853: screen_clear();
	call	_screen_clear
;ps_engine.c:854: SMS_displayOn();
	ld	hl, #0x0140
	call	_SMS_VDPturnOnFeature
00126$:
;ps_engine.c:857: title_screen();
	call	_title_screen
;ps_engine.c:858: g_level_idx = 0;
	ld	hl, #_g_level_idx
	ld	(hl), #0x00
;ps_engine.c:859: while (g_level_idx < g_nlevels) {
00118$:
	ld	hl, #_g_nlevels
;ps_engine.c:860: if (level_fetch(g_level_idx)) {           /* message "level"     */
	ld	a,(_g_level_idx+0)
	cp	a,(hl)
	jp	NC,00120$
	call	_level_fetch
	or	a, a
	jr	Z, 00102$
;ps_engine.c:861: show_message(msg_ptr);
	ld	hl, (_msg_ptr)
	call	_show_message
;ps_engine.c:862: g_level_idx++;
	ld	hl, #_g_level_idx
	inc	(hl)
;ps_engine.c:863: continue;
	jr	00118$
00102$:
;ps_engine.c:865: board_reset_view();
	call	_board_reset_view
;ps_engine.c:866: if (g_flags & FLG_RUNRULESONSTART) { turn(-1); draw_board(); }
	ld	a, (_g_flags+0)
	rrca
	jr	NC, 00125$
	ld	a, #0xff
	call	_turn
	call	_draw_board
00125$:
;ps_engine.c:870: frame_wait();
	call	_frame_wait
;ps_engine.c:871: in = poll_input();
	call	_poll_input
;ps_engine.c:872: if (in == 0xFF) continue;
	cp	a, #0xff
	jr	Z, 00125$
;ps_engine.c:873: if (in == 5) { if (undo_pop()) draw_board(); continue; }
	cp	a, #0x05
	jr	NZ, 00110$
	call	_undo_pop
	or	a, a
	jr	Z, 00125$
	call	_draw_board
	jr	00125$
00110$:
;ps_engine.c:874: if (in == 6) {
	cp	a, #0x06
	jr	NZ, 00113$
;ps_engine.c:876: undo_push(lev);
	ld	hl, #_lev
	call	_undo_push
;ps_engine.c:877: for (i = 0; i < g_ncells; i++) { lev[i] = chkpt[i]; mov[i] = 0; }
	ld	-1 (ix), #0x00
00123$:
	ld	hl, #_g_ncells
	ld	a, -1 (ix)
	sub	a, (hl)
	jr	NC, 00111$
	ld	l, -1 (ix)
;	spillPairReg hl
;	spillPairReg hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	add	hl, hl
	add	hl, hl
	ld	c, l
	ld	b, h
	ld	hl, #_lev
	add	hl, bc
	ex	de, hl
	ld	hl, #_chkpt
	add	hl, bc
	push	de
	push	bc
	ex	de, hl
	ld	hl, #4
	add	hl, sp
	ex	de, hl
	ld	bc, #0x0004
	ldir
	pop	bc
	pop	de
	push	bc
	ld	hl, #2
	add	hl, sp
	ld	bc, #0x0004
	ldir
	pop	bc
	ld	hl, #_mov
	add	hl, bc
	xor	a, a
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	-1 (ix)
	jr	00123$
00111$:
;ps_engine.c:878: draw_board();
	call	_draw_board
;ps_engine.c:879: continue;
	jr	00125$
00113$:
;ps_engine.c:881: if (post_turn(turn((s8)in))) break;   /* level complete       */
	call	_turn
	call	_post_turn
	or	a, a
	jr	Z, 00125$
;ps_engine.c:883: g_level_idx++;
	ld	hl, #_g_level_idx
	inc	(hl)
	jp	00118$
00120$:
;ps_engine.c:885: screen_clear();
	call	_screen_clear
;ps_engine.c:886: draw_text_centered(11, "CONGRATULATIONS!");
	ld	de, #___str_4
	ld	a, #0x0b
	call	_draw_text_centered
;ps_engine.c:887: draw_text_centered(14, "YOU WIN");
	ld	de, #___str_5
	ld	a, #0x0e
	call	_draw_text_centered
;ps_engine.c:888: wait_button1();
	call	_wait_button1
;ps_engine.c:890: }
	jp	00126$
___str_4:
	.ascii "CONGRATULATIONS!"
	.db 0x00
___str_5:
	.ascii "YOU WIN"
	.db 0x00
	.area _CODE
	.area _INITIALIZER
__xinit__rng_state:
	.dw #0xace1
	.area _CABS (ABS)
	.org 0x7FF0
___SMS__SEGA_signature:
	.db #0x54	; 84	'T'
	.db #0x4d	; 77	'M'
	.db #0x52	; 82	'R'
	.db #0x20	; 32
	.db #0x53	; 83	'S'
	.db #0x45	; 69	'E'
	.db #0x47	; 71	'G'
	.db #0x41	; 65	'A'
	.db #0xff	; 255
	.db #0xff	; 255
	.db #0xff	; 255
	.db #0xff	; 255
	.db #0x99	; 153
	.db #0x99	; 153
	.db #0x00	; 0
	.db #0x4c	; 76	'L'
