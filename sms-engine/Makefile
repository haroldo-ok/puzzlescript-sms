# PuzzleScript SMS base ROM
# Requires: sdcc (Z80), devkitSMS's ihx2sms on PATH (or set IHX2SMS)

IHX2SMS ?= ihx2sms
CC      := sdcc
CFLAGS  := -c -mz80

all: ps_sms_base.sms

ps_engine.rel: ps_engine.c font.h
	$(CC) $(CFLAGS) ps_engine.c

ps_sms_base.sms: ps_engine.rel
	$(CC) -o ps_sms_base.ihx -mz80 --no-std-crt0 --data-loc 0xC000 lib/crt0_sms.rel ps_engine.rel lib/SMSlib.lib
	$(IHX2SMS) ps_sms_base.ihx ps_sms_base.sms

# native test harness (runs the same rule engine on a data blob)
ps_test: ps_engine.c
	gcc -O2 -DPC_TEST -o ps_test ps_engine.c

clean:
	rm -f *.ihx *.rel *.lst *.sym *.asm *.map *.lk *.noi ps_sms_base.sms ps_test
