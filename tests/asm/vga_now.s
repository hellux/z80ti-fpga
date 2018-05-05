start:
ld c, 0x10  ; lcd status port
ld a, 0x03  ; enable lcd
out (c), a
ld a, 0x01  ; 8 bit mode
out (c), a
ld d, 0x80 ; row select, 0x80 = 0

row:
out (c), d ; set current row
ld b, 0x0c  ; number of pages per row (12)
ld a, 0x07  ; auto inc y
out (c), a

byte:
ld a, d   ; page data
out (0x11),a
dec b
jr nz, byte

next_row:
ld a, 0x20 ; set col to 0
out (c), a
inc d
ld a, d
cp 0x85 ; last row + 1
jr nz, row

halt
