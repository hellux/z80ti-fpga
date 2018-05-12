org 0x9d95
; manual example
rld_test:
ld hl, 0x0090
ld a, 0x7a
ld (hl), 0x31
rld
cp 0x73
jr nz, fail
ld a, (hl)
cp 0x1a
jr nz, fail

rrd_test:
ld hl, 0x0090
ld a, 0x84
ld (hl), 0x20
rrd
cp 0x80
jr nz, fail
ld a, (hl)
cp 0x42
jr nz, fail

success:
ld d, 0xcc
halt

fail:
ld d, 0xff
halt
