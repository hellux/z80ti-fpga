org $9d95

scf
ccf
ld a, $e1
rra
jp nc, fail
cp $70
jp nz, fail

scf
ld a, $76
rla
jp c, fail
cp $ed
jp nz, fail

success:
ld a, $cc
halt

fail:
ld a, $ee
halt
