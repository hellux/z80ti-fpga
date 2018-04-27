
ld a, 0x05
ld b, 0x06
ld c, 0x07
ld (0x000a), ix
ld (ix + d), b
1
ld (ix + d), c
2
add a, (ix + d)
2
sub a, (ix + d)
1
halt
