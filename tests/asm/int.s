org $9d95
ld a, $04
out ($03), a
in a, ($04)
res 1, a
res 2, a
out ($04), a
ld hl, 38h
ld (hl), 0xc9
im 1
ei
halt
call reti_test
ld l, 0xcc

call enable
halt

enable:
ei
reti

reti_test:
call retn_test
reti

retn_test:
ld h, 0xcc
retn
