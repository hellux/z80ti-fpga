ld a, 0x01  ; 8 bit mode
out (0x10), a
ld c, 0x10

row:
ld d, 0x40
ld a, 0x07  ; auto inc y
out (0x10), a

byte:
ld b, 0x0c
ld a, 0xaa
out (0x11),a
dec b
jp nz, byte

inc_row:
ld a, 0x05 ; auto inc x
out (0x10), a
in a, (c)
ld a, 0x80
out (0x10), a
dec d
jp nz, row

halt
