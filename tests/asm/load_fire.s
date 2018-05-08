plotSScreen: equ $9340

load buffer:
ld a, 0x80 ; row select, 0x80 = 0
ld hl, plotSScreen
ld bc, $0008 ; page size

row:
ld b, 0x0c  ; number of pages per row (12)

byte:
ld (hl), a  ; store page data
add hl,bc   ; increment ptr
dec b
jr nz, byte

next_row:
inc a
cp 0x85 ; last row + 1
jr nz, row

goto_fire:
jp 0x9d95
