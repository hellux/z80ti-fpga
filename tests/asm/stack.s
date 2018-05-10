ld sp, 0x20
inc sp
inc sp
dec sp
dec sp ; sp = 20

ld hl, 0x10
ld sp, hl ; sp = 10

ld sp, 0x01 ; address: 01
ld ix, 0xFFFF

ld hl, 0xAA
ld (0x01), hl
ld hl, 0xBB
ld (0x02), hl ; save 01: AA, 02: BB
ex (sp), ix 

ld sp, 0x10 
ld ix, 0x20
ld sp, ix ; sp = 30

ld (0x10), sp 
ld sp, (0x02) ; sp = BB

ld sp, 0x00

ld bc, 0xDD
push bc
pop de

