org $9d95
ld a, $04
out ($03), a
in a, ($04)
res 1, a
res 2, a
out ($04), a
im 1
ei
halt
