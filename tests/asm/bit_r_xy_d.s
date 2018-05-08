; rlc iy
ld a, 10010100b
ld iy, 0x70
ld (0xc0), a
rlc (iy+0x50)
jp m, fail
jp z, fail
jp pe, fail
jp nc, fail
ld a, (0xc0)
cp 00101001b

; sla ix
ld a, 10010111b
ld ix, 0x80
ld (0xe0), a
sla (ix+0x60)
jp m, fail
jp z, fail
jp po, fail
jp nc, fail
cp 00101110b

; rlc, set, res
ld ix,0x00c0
ld a, 0x0f
ld (0xd5), a
inc ix
inc ix
inc ix
inc ix
inc ix

rlc (ix+0x10)
jp c, fail
ld a, (0xd5)
cp 0x1e
jp nz, fail

set 0, (ix+0x10)
ld a, (0xd5)
cp 0x1f
jp nz, fail

res 4, (ix+0x10)
ld a, (0xd5)
cp 0x0f
jp nz, fail

success:
ld a, 0xcc
halt

fail:
ld a, 0xee
halt
