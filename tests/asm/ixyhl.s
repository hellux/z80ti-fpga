;.org $9D95

ld ix,1234

inc ixh
ld a, ixh
cp $13
jp nz, fail

dec ixl
ld a, ixl
cp $33
jp nz, fail

success:
ld a, $cc
halt

fail:
ld a, $ee
halt
