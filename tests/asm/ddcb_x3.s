org 0x9d95

;z6
    ld a, 0x00
    ld ix, 0xf000
    ld (ix+3), a

    set 0, (ix+3)           ; y0
    ld a, (0xf003)
    cp 0x01
    jp nz, fail

    set 1, (ix+3)           ; y1
    ld a, (0xf003)
    cp 0x03
    jp nz, fail

    set 2, (ix+3)           ; y2
    ld a, (0xf003)
    cp 0x07
    jp nz, fail

    set 3, (ix+3)           ; y3
    ld a, (0xf003)
    cp 0x0f
    jp nz, fail

    set 4, (ix+3)           ; y4
    ld a, (0xf003)
    cp 0x1f
    jp nz, fail

    set 5, (ix+3)           ; y5
    ld a, (0xf003)
    cp 0x3f
    jp nz, fail

    set 6, (ix+3)           ; y6
    ld a, (0xf003)
    cp 0x7f
    jp nz, fail

    set 7, (ix+3)           ; y7
    ld a, (0xf003)
    cp 0xff
    jp nz, fail

success:
    ld a, 0xcc
    halt
fail:
    ld a, 0xee
    halt
