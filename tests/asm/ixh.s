org 0x9d95

ld a, 0xfe
ld ix, 0xabcd
; and ixh
db 0xdd
db 0xa4
jp p, fail
jp z, fail
jp po, fail
jp c, fail
cp 0xaa
jp nz, fail

success:
ld a, 0xcc
halt

fail:
ld a, 0xee
halt
