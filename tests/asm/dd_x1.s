org 0x9d95

; y4
    ld b, 0xbb
    ld ixh, b               ; z0
    dw 0x7cdd ; ld a, ixh
    cp 0xbb
    jp nz, fail

    ld c, 0xcc
    ld ixh, c               ; z1
    dw 0x7cdd ; ld a, ixh
    cp 0xcc
    jp nz, fail

    ld d, 0xdd
    ld ixh, d               ; z2
    dw 0x7cdd ; ld a, ixh
    cp 0xdd
    jp nz, fail

    ld e, 0xee
    ld ixh, e               ; z3
    dw 0x7cdd ; ld a, ixh
    cp 0xee
    jp nz, fail

    ld h, 0x44
    ld ixh, ixh             ; z4
    dw 0x7cdd ; ld a, ixh
    cp 0xee
    jp nz, fail
    ld a, h
    cp 0x44
    jp nz, fail

    ld ix, 0x2421
    ld ixh, ixl             ; z5
    dw 0x7cdd ; ld a, ixh
    cp 0x21
    jp nz, fail
    dw 0x7ddd ; ld a, ixl
    cp 0x21
    jp nz, fail
                            ; z6 above

    ld a, 0xaa              ; z7
    ld ixh, a
    dw 0x7cdd ; ld a, ixh
    cp 0xaa
    jp nz, fail

; y5
    ld ixl, b               ; z0
    dw 0x7ddd ; ld a, ixl
    cp 0xbb
    jp nz, fail

    ld ixl, c               ; z1
    dw 0x7ddd ; ld a, ixl
    cp 0xcc
    jp nz, fail

    ld ixl, d               ; z2
    dw 0x7ddd ; ld a, ixl
    cp 0xdd
    jp nz, fail

    ld ixl, e               ; z3
    dw 0x7ddd ; ld a, ixl
    cp 0xee
    jp nz, fail

    ld ix, 0x2421
    ld ixl, ixh             ; z4
    dw 0x7ddd ; ld a, ixl
    cp 0x24
    jp nz, fail
    
    ld l, 0x11
    ld ixl, ixl             ; z5
    dw 0x7ddd ; ld a, ixl
    cp 0x24
    jp nz, fail
    ld a, l
    cp 0x11
    jp nz, fail
                            ; z6 above

    ld a, 0xaa
    ld ixl, a               ; z7
    dw 0x7ddd ; ld a, ixl
    cp 0xaa
    jp nz, fail

; z4
    ld ix, 0x2421
    ld b, ixh               ; y0
    ld a, b
    cp 0x24
    jp nz, fail
    ld c, ixh               ; y1
    ld a, c
    cp 0x24
    jp nz, fail
    ld d, ixh               ; y2
    ld a, d
    cp 0x24
    jp nz, fail
    ld e, ixh               ; y3
    ld a, e
    cp 0x24
    jp nz, fail
                            ; y4 above
                            ; y5 above
                            ; y6 above
    ld a, 0x00
    dw 0x7cdd ; ld a, ixh   ; y7
    cp 0x24
    jp nz, fail

; y6
    ld ix, 0xf010

    ld b, 0xbb
    ld (ix+0), b            ; z0
    ld (0xf000), a
    cp 0xbb

    ld c, 0xbb
    ld (ix+1), c            ; z1
    ld (0xf001), a
    cp 0xcc

    ld d, 0xdd
    ld (ix+2), d            ; z2
    ld (0xf002), a
    cp 0xdd

    ld e, 0xee
    ld (ix+3), e            ; z3
    ld (0xf003), a
    cp 0xee

    ld h, 0x44
    ld (ix+4), h            ; z4
    ld (0xf004), a
    cp 0x44

    ld l, 0x11
    ld (ix+5), l            ; z5
    ld (0xf005), a
    cp 0x11

    ld a, 0xaa
    ld (ix+6), a            ; z7
    ld (0xf006), a
    cp 0xaa

; z5
    ld ix, 0x2421
    ld b, ixl               ; y0
    ld a, b
    cp 0x21
    jp nz, fail
    ld c, ixl               ; y1
    ld a, c
    cp 0x21
    jp nz, fail
    ld d, ixl               ; y2
    ld a, d
    cp 0x21
    jp nz, fail
    ld e, ixl               ; y3
    ld a, e
    cp 0x21
    jp nz, fail
                            ; y4 above
                            ; y5 above
                            ; y6 above
    ld a, 0x00
    dw 0x7ddd ; ld a, ixl   ; y7
    cp 0x21
    jp nz, fail

; z6
    ld hl, 0xf000
    ld ix, 0xf000
    ld (hl), 0xbb
    inc hl
    ld (hl), 0xcc
    inc hl
    ld (hl), 0xdd
    inc hl
    ld (hl), 0xee
    inc hl
    ld (hl), 0x44
    inc hl
    ld (hl), 0x11
    inc hl
    ld (hl), 0xaa
    ld b, (ix+0)            ; y0
    ld a, b
    cp 0xbb
    jp nz, fail
    ld c, (ix+1)            ; y1
    ld a, c
    cp 0xcc
    jp nz, fail
    ld d, (ix+2)            ; y2
    ld a, d
    cp 0xdd
    jp nz, fail
    ld e, (ix+3)            ; y3
    ld a, e
    cp 0xee
    jp nz, fail
    ld h, (ix+4)            ; y4
    ld a, h
    cp 0x44
    jp nz, fail
    ld l, (ix+5)            ; y5
    ld a, l
    cp 0x11
    jp nz, fail
                            ; y6 noni
    ld a, (ix+6)            ; y7
    cp 0xaa
    jp nz, fail

; z7 noni

success:
    ld a, 0xcc
    halt
fail:
    ld a, 0xee
    halt
