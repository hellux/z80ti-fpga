org 0x9d95
scf
call c, test
call nc, fail
halt

test:
ld a, 0xcc
ret

fail:
ld a, 0xee
ret
