ld a, 0x43
rrca
jr nc, fail
cp 0xa1
jr nz, fail

ld a, 0x42
jr c, fail
rrca
cp 0x21
jr nz, fail

success:
ld a, 0xcc
halt

fail:
ld a, 0xee
halt
