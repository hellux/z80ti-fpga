org 0x9d95
fact1: equ 4
fact2: equ 8

ld b, fact1     ; x
ld e, fact2     ; y
ld a, 0     ; x*y
call multiply

cp fact1*fact2
jp nz, fail

success:
ld a, 0xcc
halt

fail:
ld a, 0xee
halt

multiply:
inc b
loop:
djnz continue
ret
continue:
add a, e
jr loop
