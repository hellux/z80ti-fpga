org 0x9d95
ld a, 0x01
ld (0x70), a
ld a, 0x02
ld (0x71), a
ld a, 0x03
ld (0x72), a
ld a, 0x04
ld (0x73), a

ld bc, 0x03
ld hl, 0x70
ld de, 0x80

cpi_test:
ld a, 0x01
cpi
jp nz, fail
jp m, fail
jp nc, fail
jp po, fail
ld a, l
cp 0x71     ; test hl
jr nz, fail
ld a, c
cp 0x02     ; test bc
jr nz, fail

cpir_test:
ld a, 0x03
cpir
jp m, fail
jp c, fail
jp pe, fail
jp nz, fail
ld a, l
cp 0x73     ; test hl
jr nz, fail
ld a, c
cp 0x00     ; test bc
jr nz, fail

success:
ld d, 0xcc
halt

fail:
ld d, 0xff
halt

