PRJ  := ps_base_rom
OBJS := ps_engine.rel font.rel
IHX2SMS ?= ihx2sms

all: $(PRJ).sms

%.rel: %.c
	sdcc -c -mz80 --opt-code-speed --peep-file lib/peep-rules.txt $<

$(PRJ).sms: $(OBJS)
	sdcc -o $(PRJ).ihx -mz80 --no-std-crt0 --data-loc 0xC000 lib/crt0_sms.rel $(OBJS) lib/SMSlib.lib
	$(IHX2SMS) $(PRJ).ihx $(PRJ).sms

clean:
	rm -f *.sms *.ihx *.rel *.asm *.sym *.lst *.map *.lk *.noi *.mem *.rst
