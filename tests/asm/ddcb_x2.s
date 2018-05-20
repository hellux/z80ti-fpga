org 0x9d95

;z6
    ld a, 0xff
    ld ix, 0xf000
    ld (ix+3), a

    res 0, (ix+3)           ; y0
    ld a, (0xf003)
    cp 0xfe
    jp nz, fail

    res 1, (ix+3)           ; y1
    ld a, (0xf003)
    cp 0xfc
    jp nz, fail

    res 2, (ix+3)           ; y2
    ld a, (0xf003)
    cp 0xf8
    jp nz, fail

    res 3, (ix+3)           ; y3
    ld a, (0xf003)
    cp 0xf0
    jp nz, fail

    res 4, (ix+3)           ; y4
    ld a, (0xf003)
    cp 0xe0
    jp nz, fail

    res 5, (ix+3)           ; y5
    ld a, (0xf003)
    cp 0xc0
    jp nz, fail

    res 6, (ix+3)           ; y6
    ld a, (0xf003)
    cp 0x80
    jp nz, fail

    res 7, (ix+3)           ; y7
    ld a, (0xf003)
    cp 0x00
    jp nz, fail

success:
    ld a, 0xcc
    halt
fail:
    ld a, 0xee
    halt
