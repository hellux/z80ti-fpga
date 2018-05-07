cp $01
ld b, $02

loop:
djnz loop
ld sp, $ffff
ld ix, $0001
add ix, sp
jr nc, fail
jr z, fail
;jr p, fail

success:
ld a, $cc
halt

fail:
ld a, $ee
halt
