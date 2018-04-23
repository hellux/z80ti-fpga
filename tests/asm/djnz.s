init:
ld b, 4     ; x
ld e, 8     ; y
ld a, 0     ; x*y

inc b
loop:
djnz continue
halt

continue:
add a, e
jr loop
