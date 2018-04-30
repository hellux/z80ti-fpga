ld c, 0x10  ; lcd status port
ld a, 0x01  ; 8 bit mode
out (c), a
ld d, 0x04  ; number of rows (64)

row:
ld b, 0x02  ; number of pages per row (12)
ld a, 0x07  ; auto inc y
out (c), a

byte:
ld a, 0xaa   ; page data
out (0x11),a
dec b
jr nz, byte

next_row:
ld a, 0x05 ; auto inc x
out (c), a
in a, (0x11) ; read to auto inc
ld a, 0x20 ; set col to 0
out (c), a
dec d
jr nz, row

halt
