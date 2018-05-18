org 0x9d95

or a
ld hl, 0x1e
ld de, 0x0a
sbc hl, de
jp m, fail
jp z, fail
jp pe, fail
jp c, fail
ld a, h
cp 0x00
jp nz, fail
ld a, l
cp 0x14
jp nz, fail

ld a, 0
add a, 1 ; reset flags
ld hl, 0x001a
ld de, 0x001a
add hl, de
add hl, de
add hl, de
add hl, de
jp m, fail
jp z, fail
jp pe, fail
jp c, fail
ld a, h
cp 0x00
jp nz, fail
ld a, l
cp 0x82
jp nz, fail

ld a, 0
add a, 1 ; reset flags
ld bc, 0x0123
ld de, 0x4567
ld ix, 0x89ab
ld sp, 0xcdef

add ix, ix
jp m, fail
jp z, fail
jp pe, fail
jp nc, fail
dw 0x7cdd ; ld a, ixh
cp 0x13
jp nz, fail
dw 0x7ddd ; ld a, ixl
cp 0x56
jp nz, fail

add ix, bc
jp c, fail
dw 0x7cdd ; ld a, ixh
cp 0x14
jp nz, fail
dw 0x7ddd ; ld a, ixl
cp 0x79
jp nz, fail

add ix, de
dw 0x7cdd ; ld a, ixh
cp 0x59
jp nz, fail
dw 0x7ddd ; ld a, ixl
cp 0xe0
jp nz, fail

add ix, sp
jp nc, fail
dw 0x7cdd ; ld a, ixh
cp 0x27
jp nz, fail
dw 0x7ddd ; ld a, ixl
cp 0xcf
jp nz, fail

success:
ld a, 0xcc
halt

fail:
ld a, 0xee
halt
