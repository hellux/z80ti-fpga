org 0x9d95

ld b, 4
loop:
add a, 10 ; reset zero flag
djnz loop ; set internal zero flag when b = 0
jp z, fail ; assert zero flag unchanged

success:
ld a, 0xcc
halt

fail:
ld a, 0xee
halt
