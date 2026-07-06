global.window = global;
/* Minimal headless Sega Master System for testing PuzzleScript SMS ROMs.
   Requires Z80.js next to this file: run ./get_z80js.sh once (MIT licensed,
   from https://github.com/DrGoldfire/Z80.js).

   Usage: node smsrun.js <rom.sms> <script> <out-prefix>
   script: comma list like  "120,1:10,30,U:5,30,shot"
     N        run N frames
     U/D/L/R  hold dpad for the following frame count segment "U:12"
     1/2      hold button for "1:10"
     shot     dump screenshot (PPM) + tilemap text
*/
'use strict';
const fs = require('fs');
const Z80 = require(require('path').join(__dirname, 'Z80.js'));

const romPath = process.argv[2];
const script = process.argv[3] || '300,shot';
const outPrefix = process.argv[4] || 'out';

const rom = fs.readFileSync(romPath);
const nbanks = Math.max(3, Math.ceil(rom.length / 16384));
const banks = [];
for (let i = 0; i < nbanks; i++) {
    const b = new Uint8Array(16384);
    b.set(rom.subarray(i * 16384, Math.min((i + 1) * 16384, rom.length)));
    banks.push(b);
}
const ram = new Uint8Array(8192);
const mapper = [0, 0, 1, 2];      // [ctrl, slot0, slot1, slot2]

/* ---- VDP ---- */
const vram = new Uint8Array(16384);
const cram = new Uint8Array(32);
const vreg = new Uint8Array(16);
let vaddr = 0, vcode = 0, vlatch = -1, vbuf = 0, vstatus = 0;
let lineCounter = 0xFF, irqLine = false;

function vdpControlWrite(v) {
    if (vlatch < 0) { vlatch = v; return; }
    const lo = vlatch; vlatch = -1;
    vaddr = ((v & 0x3F) << 8) | lo;
    vcode = v >> 6;
    if (vcode === 0) { vbuf = vram[vaddr & 0x3FFF]; vaddr = (vaddr + 1) & 0x3FFF; }
    else if (vcode === 2) { vreg[v & 0x0F] = lo; }
}
function vdpDataWrite(v) {
    vlatch = -1;
    if (vcode === 3) cram[vaddr & 0x1F] = v;
    else vram[vaddr & 0x3FFF] = v;
    vaddr = (vaddr + 1) & 0x3FFF;
}
function vdpDataRead() {
    vlatch = -1;
    const r = vbuf;
    vbuf = vram[vaddr & 0x3FFF];
    vaddr = (vaddr + 1) & 0x3FFF;
    return r;
}
function vdpStatusRead() {
    const s = vstatus; vstatus = 0; vlatch = -1; irqLine = false;
    return s;
}

/* ---- pads ---- */
let padA = 0xFF; // active low

/* ---- CPU glue ---- */
function mem_read(a) {
    a &= 0xFFFF;
    if (a < 0x0400) return banks[0][a];
    if (a < 0x4000) return banks[mapper[1] % nbanks][a];
    if (a < 0x8000) return banks[mapper[2] % nbanks][a - 0x4000];
    if (a < 0xC000) return banks[mapper[3] % nbanks][a - 0x8000];
    return ram[a & 0x1FFF];
}
let watchAddr = -1;
function mem_write(a, v) {
    a &= 0xFFFF; v &= 0xFF;
    if (a === watchAddr) {
        const st = core ? core.getState() : {pc:0};
        console.log('WRITE 0x'+a.toString(16)+' = 0x'+v.toString(16)+' from PC 0x'+st.pc.toString(16)+' SP 0x'+st.sp.toString(16)+' @frame '+frame);
    }
    if (a >= 0xFFFC) mapper[a - 0xFFFC] = v;
    if (a >= 0xC000) ram[a & 0x1FFF] = v;
}
let core;
function io_read(p) {
    p &= 0xFF;
    if (p === 0x7E) return curLine < 0xDB ? curLine : 0xDB; // V counter approx
    if (p === 0x7F) return 0;
    if ((p & 0xC1) === 0x40) return curLine & 0xFF;
    if (p === 0xBE) return vdpDataRead();
    if (p === 0xBF || p === 0xBD) return vdpStatusRead();
    if (p === 0xDC || p === 0xC0) return padA;
    if (p === 0xDD || p === 0xC1) return 0xFF;
    return 0xFF;
}
function io_write(p, v) {
    p &= 0xFF;
    if (p === 0xBE) vdpDataWrite(v);
    else if (p === 0xBF || p === 0xBD) vdpControlWrite(v);
    /* PSG (0x7E/0x7F), mem ctrl: ignored */
}

core = Z80({ mem_read, mem_write, io_read, io_write });
core.reset();

/* ---- frame loop ---- */
const CYCLES_PER_LINE = 228, LINES = 262, VBLANK_LINE = 192;
let curLine = 0;
let frame = 0;

function runFrame() {
    for (curLine = 0; curLine < LINES; curLine++) {
        let c = 0;
        if (curLine === VBLANK_LINE) {
            vstatus |= 0x80;
            if (vreg[1] & 0x20) irqLine = true;
        }
        while (c < CYCLES_PER_LINE) {
            if (irqLine && core.getState().iff1) core.interrupt(false, 0xFF);
            c += core.run_instruction() || 4;
        }
    }
    frame++;
}

/* ---- screenshot ---- */
function smsColor(b) {
    const conv = v => [0, 85, 170, 255][v & 3];
    return [conv(b), conv(b >> 2), conv(b >> 4)];
}
function screenshot(name) {
    const ntBase = (vreg[2] & 0x0E) << 10;
    const W = 256, H = 192;
    const img = Buffer.alloc(W * H * 3);
    for (let ty = 0; ty < 24; ty++) {
        for (let tx = 0; tx < 32; tx++) {
            const e = ntBase + (ty * 32 + tx) * 2;
            const lo = vram[e], hi = vram[e + 1];
            const tile = ((hi & 1) << 8) | lo;
            const pal = (hi & 0x08) ? 16 : 0;
            const hflip = hi & 2, vflip = hi & 4;
            for (let r = 0; r < 8; r++) {
                const rr = vflip ? 7 - r : r;
                const base = tile * 32 + rr * 4;
                for (let cc = 0; cc < 8; cc++) {
                    const c = hflip ? 7 - cc : cc;
                    const bit = 0x80 >> c;
                    let idx = 0;
                    if (vram[base] & bit) idx |= 1;
                    if (vram[base + 1] & bit) idx |= 2;
                    if (vram[base + 2] & bit) idx |= 4;
                    if (vram[base + 3] & bit) idx |= 8;
                    const rgb = smsColor(cram[pal + idx]);
                    const px = ((ty * 8 + r) * W + tx * 8 + cc) * 3;
                    img[px] = rgb[0]; img[px + 1] = rgb[1]; img[px + 2] = rgb[2];
                }
            }
        }
    }
    fs.writeFileSync(name + '.ppm', Buffer.concat([Buffer.from(`P6\n${W} ${H}\n255\n`), img]));

    /* text view: font tiles back to ASCII, combo tiles as '#', blank '.' */
    let txt = '';
    for (let ty = 0; ty < 24; ty++) {
        for (let tx = 0; tx < 32; tx++) {
            const e = ntBase + (ty * 32 + tx) * 2;
            const tile = ((vram[e + 1] & 1) << 8) | vram[e];
            if (tile === 0) txt += '.';
            else if (tile >= 352 && tile < 448) txt += String.fromCharCode(32 + tile - 352);
            else txt += '#';
        }
        txt += '\n';
    }
    fs.writeFileSync(name + '.txt', txt);
    console.log('shot -> ' + name + '.ppm/.txt @frame ' + frame);
}

/* ---- run the script ---- */
let shotIdx = 0;
for (const step of script.split(',')) {
    if (step === 'shot') { screenshot(`${outPrefix}_${String(shotIdx++).padStart(2, '0')}`); continue; }
    let tm = step.match(/^tracerule:(\d+)$/);
    if (tm) {
        for (let f=0; f<+tm[1]; f++) {
            for (curLine=0; curLine<LINES; curLine++) {
                let c=0;
                if (curLine===VBLANK_LINE){vstatus|=0x80; if(vreg[1]&0x20) irqLine=true;}
                while (c<CYCLES_PER_LINE) {
                    if (irqLine && core.getState().iff1) core.interrupt(false,0xFF);
                    const st=core.getState();
                    if (st.pc===0x1564) { // run_rule entry: HL = pp
                        const hl=(st.h<<8)|st.l;
                        const ptr=mem_read(hl)|(mem_read(hl+1)<<8);
                        const bytes=[]; for(let k=0;k<8;k++) bytes.push(mem_read(ptr+k).toString(16).padStart(2,'0'));
                        console.log('run_rule pp@0x'+hl.toString(16)+' rule@0x'+ptr.toString(16)+' bytes '+bytes.join(' '));
                    }
                    c+=core.run_instruction()||4;
                }
            }
            frame++;
        }
        continue;
    }
    let wpm = step.match(/^wp:([0-9a-fA-F]+)$/);
    if (wpm) { watchAddr = parseInt(wpm[1],16); console.log('watchpoint @0x'+wpm[1]); continue; }
    let wm = step.match(/^watch:(\d+)$/);
    if (wm) {
        const watches = {
            0x207A:'do_turn',0x1564:'run_rule',0x189B:'run_rule_groups',0x1AF5:'resolve_movements',
            0x1C84:'check_win_conditions',0x56D:'wait_button',0x491:'draw_message_text',
            0xA07:'level_is_message',0xA11:'load_level_data',0x203F:'show_message_fp',
            0x2348:'do_restart',0x263E:'run_again_chain',0x25CA:'win_screen',0x2527:'title_screen',
            0x8B8:'draw_dirty',0x886:'draw_all',0x139F:'enum_rows',0x12C6:'apply_tuple',0x1FF4:'undo_pop'
        };
        const counts={};
        for (let f=0; f<+wm[1]; f++) {
            for (curLine=0; curLine<LINES; curLine++) {
                let c=0;
                if (curLine===VBLANK_LINE){vstatus|=0x80; if(vreg[1]&0x20) irqLine=true;}
                while (c<CYCLES_PER_LINE) {
                    if (irqLine && core.getState().iff1) core.interrupt(false,0xFF);
                    const pc=core.getState().pc;
                    if (watches[pc]) counts[watches[pc]]=(counts[watches[pc]]||0)+1;
                    c+=core.run_instruction()||4;
                }
            }
            frame++;
        }
        console.log('watch:', JSON.stringify(counts));
        continue;
    }
    let pm = step.match(/^prof:(\d+)$/);
    if (pm) {
        const hist = {};
        const frames = +pm[1];
        for (let f = 0; f < frames; f++) {
            for (curLine = 0; curLine < LINES; curLine++) {
                let c = 0;
                if (curLine === VBLANK_LINE) { vstatus |= 0x80; if (vreg[1] & 0x20) irqLine = true; }
                while (c < CYCLES_PER_LINE) {
                    if (irqLine && core.getState().iff1) core.interrupt(false, 0xFF);
                    const pc = core.getState().pc;
                    hist[pc] = (hist[pc] || 0) + 1;
                    c += core.run_instruction() || 4;
                }
            }
            frame++;
        }
        const top = Object.entries(hist).sort((a,b)=>b[1]-a[1]).slice(0,25);
        for (const [pc,n] of top) console.log('PC 0x'+(+pc).toString(16).padStart(4,'0'), n);
        continue;
    }
    let rm = step.match(/^ram:([0-9a-fA-F]+):(\d+)$/);
    if (rm) {
        const a0 = parseInt(rm[1],16); const len = +rm[2];
        let out='';
        for (let i=0;i<len;i++){ out += mem_read(a0+i).toString(16).padStart(2,'0'); if(i%16===15) out+='\n'; else out+=' ';}
        console.log('RAM @'+rm[1]+':\n'+out);
        continue;
    }
    const m = step.match(/^([UDLR12]):(\d+)$/);
    if (m) {
        const bit = { U: 1, D: 2, L: 4, R: 8, '1': 16, '2': 32 }[m[1]];
        padA = 0xFF & ~bit;
        for (let i = 0; i < +m[2]; i++) runFrame();
        padA = 0xFF;
        continue;
    }
    const n = parseInt(step, 10);
    for (let i = 0; i < n; i++) runFrame();
}
console.log('done, ' + frame + ' frames');
