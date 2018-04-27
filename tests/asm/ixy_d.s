ld a, 0x05
ld b, 0x06
ld c, 0x07
ld ix, 0x40
ld (ix + 1), b
ld (ix + 2), c
add a, (ix + 2)
sub a, (ix + 1)
ld iy,0x40
ld d, (iy+1)
ld e, (iy+2)
ld (ix + 3),0xF
ld (iy + 1),0xD
inc (ix + 2)
dec (ix + 2)
halt
