ld hl, 6
ld de, 50
ldi
ld c, 2
ld h, d
ld l, e
ini
ld c, 1
ld (hl), 0x33
outi
halt
