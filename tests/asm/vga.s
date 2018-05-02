jr start

gbuf: dw 0xf0

start:
di
ld c, 0x10  ; lcd status port
call wait_for_lcd
ld a, 0x03  ; enable lcd
out (c), a
call wait_for_lcd
ld a, 0x01  ; 8 bit mode
out (c), a
ld d, 0x80 ; row select, 0x80 = 0

row:
call wait_for_lcd
out (c), d ; set current row
ld b, 0x0c  ; number of pages per row (12)
call wait_for_lcd
ld a, 0x07  ; auto inc y
out (c), a

byte:
call wait_for_lcd
ld a, d   ; page data
out (0x11),a
dec b
jr nz, byte

next_row:
call wait_for_lcd
ld a, 0x20 ; set col to 0
out (c), a
inc d
ld a, d
cp 0xc0 ; number of rows
jr nz, row

halt

wait_for_lcd:
in a, (0x10)
bit 7, a
jr nz, wait_for_lcd
ret
