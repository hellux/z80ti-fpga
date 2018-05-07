ld a, 0x01
ld (0x70), a
ld a, 0x02
ld (0x71), a
ld a, 0x03
ld (0x72), a
ld a, 0x04
ld (0x73), a
ld a, 0x05
ld (0x74), a
ld a, 0x06
ld (0x75), a

ld bc, 0x05
ld hl, 0x70
ld de, 0x80

ldi_test:
ldi
jp po, fail
jp p, fail
jp nz, fail
jp nc, fail
ld a, l
cp 0x71     ; test hl
jr nz, fail
ld a, e
cp 0x81     ; test de
jr nz, fail
ld a, c
cp 0x04     ; test bc
jr nz, fail

ldir_test:
ldir
jp m, fail
jp nz, fail
jp c, fail
jp pe, fail
ld a, l
cp 0x75     ; test hl
jr nz, fail
ld a, e
cp 0x85     ; test de
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

