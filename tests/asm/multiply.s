init:
ld d, 4     ; x
ld e, 8     ; y
ld a, 0     ; x*y

inc d
loop:
dec d
jr nz, continue
halt

continue:
add a, e
jr loop
