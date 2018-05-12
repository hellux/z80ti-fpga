org 0x9d95

ld b, 4     ; x
ld e, 8     ; y
ld a, 0     ; x*y
call multiply
halt

multiply:
inc b
loop:
djnz continue
ret
continue:
add a, e
jr loop
