ld hl, 40101
ld bc, 10038
add hl, bc
ld hl, 0xffff
ld de, 0xffff
add hl, de
ld hl, 0xd6c3
ld de, 0x5b69
scf
ccf
sbc hl, de
ld ix, 0xd6c3
ld sp, 0x5b69
scf
ccf
sbc hl, sp
halt
