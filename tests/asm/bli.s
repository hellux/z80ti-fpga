ld hl, 6
ld de, 0xff80
ldi
ld c, 2
ld h, d
ld l, e
ini
ld c, 1
ld (hl), 0x33
ld b, 0x02
otir
halt
