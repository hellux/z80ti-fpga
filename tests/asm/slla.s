org 0x9d95

ld hl, 0xa300
push hl
pop af
; sll a
db 0xcb
db 0x37
jp m, fail
jp z, fail
jp po, fail
jp nc, fail
cp 0x47
jp nz, fail

success:
ld a, 0xcc
halt

fail:
ld a, 0xee
halt
