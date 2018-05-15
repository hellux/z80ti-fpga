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

loop:
add a, 1
add a, 2
add a, 3
add a, 4
add a, 5
add a, 6
add a, 7
jr loop

call reti_test
ld l, 0xcc

call enable
ld a, 0x80
out ($03), a
ld a, 0x0f
out ($03), a
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
