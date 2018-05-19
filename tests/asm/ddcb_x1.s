org 0x9d95

    ld a, 11000110b
    ld ix, 0xf000
    ld (ix+3), a

; z6
    bit 0, (ix+3)           ; y0
    jp nz, fail
    bit 1, (ix+3)           ; y1
    jp z, fail
    bit 2, (ix+3)           ; y2
    jp z, fail
    bit 3, (ix+3)           ; y3
    jp nz, fail
    bit 4, (ix+3)           ; y4
    jp nz, fail
    bit 5, (ix+3)           ; y5
    jp nz, fail
    bit 6, (ix+3)           ; y6
    jp z, fail
    bit 7, (ix+3)           ; y7
    jp z, fail

success:
    ld a, 0xcc
    halt
fail:
    ld a, 0xee
    halt
