; rlc iy
ld a, 10010100b
ld iy, 0x70
ld (0x80), a
rlc (iy+0x10)
jp m, fail
jp z, fail
jp pe, fail
jp nc, fail
ld a, (0x80)
cp 00101001b

; sla ix
ld a, 10010111b
ld ix, 0x80
ld (0xa0), a
sla (ix+0x20)
jp m, fail
jp z, fail
jp po, fail
jp nc, fail
cp 00101110b

success:
ld a, 0xcc
halt

fail:
ld a, 0xee
halt
