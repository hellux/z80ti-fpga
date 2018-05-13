start:
di

init_lcd:
ld a, 0x03  ; enable lcd
call send_command;
ld a, 0x00  ; 8 bit mode
call send_command;
ld a, 0x07  ; auto inc y
call send_command;

ld d, 0x80 ; row select, 0x80 = 0

row:
ld a, d ; set current row
call send_command;

ld b, 0x0f  ; number of pages per row (12)

byte:
ld a, d   ; page data
call send_data;
dec b
jr nz, byte

next_row:
ld a, 0x20 ; set col to 0
call send_command;

inc d
; test z addr
ld a, d
cp 0xa0 ; middle row
jr nz, z_skip
ld a, 0x57
call send_command
z_skip:
ld a, d
cp 0xc0 ; last row + 1
jr nz, row

halt

send_data:
push af
in a, (0x10)
bit 7, a
jr nz, send_data
pop af
out ($11), a
ret

send_command:
push af
in a, (0x10)
bit 7, a
jr nz, send_command
pop af
out ($10), a
ret
