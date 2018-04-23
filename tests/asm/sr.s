ld a, 10
loop:
call dec
jp nz, loop
halt

dec:
dec a
ret
