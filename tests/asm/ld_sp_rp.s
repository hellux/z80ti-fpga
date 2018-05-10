org 0x9d95

ld hl, 0x1234

ld sp, hl
ld hl, 0x1111
add hl, sp
ld a, h
cp 0x23
jp nz, fail
ld a, l
cp 0x45
jp nz, fail

ld ix, 0x5678
ld sp, ix
ld hl, 0x0000
add hl, sp
ld a, h
cp 0x56
jp nz, fail
ld a, l
cp 0x78
jp nz, fail

ld iy, 0x9abc
ld sp, iy
ld hl, 0x0000
add hl, sp
ld a, h
cp 0x9a
jp nz, fail
ld a, l
cp 0xbc
jp nz, fail

success:
ld a, 0xcc
halt

fail:
ld a, 0xee
halt
