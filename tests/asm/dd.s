;org 0x9d95
; total: 830 us

; x0

; z0 noni

; z1

    ld ix, 0x89ab           ; q0, p2
    add ix, ix              ; q1, p0
    dw 0x7cdd ; ld a, ixh
    cp 0x13
    jp nz, fail
    dw 0x7ddd ; ld a, ixl
    cp 0x56
    jp nz, fail

    ld bc, 0x0123
    add ix, bc              ; q1, p1
    dw 0x7cdd ; ld a, ixh
    cp 0x14
    jp nz, fail
    dw 0x7ddd ; ld a, ixl
    cp 0x79
    jp nz, fail

    ld de, 0x4567
    add ix, de              ; q1, p2
    dw 0x7cdd ; ld a, ixh
    cp 0x59
    jp nz, fail
    dw 0x7ddd ; ld a, ixl
    cp 0xe0
    jp nz, fail

    ld hl, 0x000
    add hl, sp
    ld sp, 0xcdef
    add ix, sp              ; q1, p3
    dw 0x7cdd ; ld a, ixh
    cp 0x27
    jp nz, fail
    dw 0x7ddd ; ld a, ixl
    cp 0xcf
    jp nz, fail
    ld sp, hl

; z2 
    ld (0xf000), ix         ; q0, p2
    ld a, (0xf001)
    cp 0x27
    jp nz, fail
    ld a, (0xf000)
    cp 0xcf
    jp nz, fail

    ld ix, 0x0000
    ld ix, (0xf000)         ; q1, p2
    dw 0x7cdd ; ld a, ixh
    cp 0x27
    jp nz, fail
    dw 0x7ddd ; ld a, ixl
    cp 0xcf
    jp nz, fail

; z3
    ld ix, 0x27ff
    inc ix                  ; q0; p2
    dw 0x7cdd ; ld a, ixh
    cp 0x28
    jp nz, fail
    dw 0x7ddd ; ld a, ixl
    cp 0x00
    jp nz, fail

    dec ix                  ; q1; p2
    dw 0x7cdd ; ld a, ixh
    cp 0x27
    jp nz, fail
    dw 0x7ddd ; ld a, ixl
    cp 0xff
    jp nz, fail

; z4
    dw 0x24dd ; inc ixh     ; y4
    dw 0x7cdd ; ld a, ixh
    cp 0x28
    jp nz, fail
    dw 0x7ddd ; ld a, ixl
    cp 0xff
    jp nz, fail

    dw 0x2cdd ; inc ixl     ; y5
    dw 0x7cdd ; ld a, ixh
    cp 0x28
    jp nz, fail
    dw 0x7ddd ; ld a, ixl
    cp 0x00
    jp nz, fail
    
    ld ix, 0xf000
    ld a, 0x05
    ld (0xf009), a
    inc (ix+9)              ; y5
    ld a, (0xf009)
    cp 0x06
    jp nz, fail

; z5
    dw 0x25dd ; dec ixh     ; y4
    dw 0x7cdd ; ld a, ixh
    cp 0xef
    jp nz, fail
    dw 0x7ddd ; ld a, ixl
    cp 0x00
    jp nz, fail

    dw 0x2ddd ; dec ixl     ; y5
    dw 0x7cdd ; ld a, ixh
    cp 0xef
    jp nz, fail
    dw 0x7ddd ; ld a, ixl
    cp 0xff
    jp nz, fail
    
    ld ix, 0xf000
    dec (ix+9)              ; y5
    ld a, (0xf009)
    cp 0x05
    jp nz, fail

; z6
    ld ixh, 0x24            ; y4
    dw 0x7cdd ; ld a, ixh
    cp 0x24
    jp nz, fail

    ld ixl, 0xe3            ; y5
    dw 0x7ddd ; ld a, ixl
    cp 0xe3
    jp nz, fail

    ld ix, 0xf000           ; y6
    ld (ix+9), 0x9a
    ld a, (0xf009)
    cp 0x9a
    jp nz, fail

; z7 noni

; x1

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

; x2

; z0 noni
; z1 noni
; z2 noni
; z3 noni

; z4
    ld ix, 0x2421

    ld a, 0x12
    dw 0x84dd ; add a, ixh  ; y0
    cp 0x36
    jp nz, fail

    scf
    ld a, 0x12
    dw 0x8cdd ; adc a, ixh  ; y1
    cp 0x37
    jp nz, fail

    ld a, 0x25
    dw 0x94dd ; sub ixh     ; y2
    cp 0x01
    jp nz, fail

    scf
    ld a, 0x25
    dw 0x9cdd ; sbc ixh     ; y3
    cp 0x00
    jp nz, fail

    ld a, 0xa9
    dw 0xa4dd ; and ixh     ; y4
    cp 0x20
    jp nz, fail

    ld a, 0xa1
    dw 0xacdd ; xor ixh     ; y6
    cp 0x85
    jp nz, fail

    ld a, 0xa1
    dw 0xb4dd ; or ixh      ; y6
    cp 0xa5
    jp nz, fail

    ld a, 0x24
    dw 0xbcdd ; cp ixh      ; y7
    jp nz, fail

; z5
    ld ix, 0x2124

    ld a, 0x12
    dw 0x85dd ; add a, ixl  ; y0
    cp 0x36
    jp nz, fail

    scf
    ld a, 0x12
    dw 0x8ddd ; adc a, ixl  ; y1
    cp 0x37
    jp nz, fail

    ld a, 0x25
    dw 0x95dd ; sub ixl     ; y2
    cp 0x01
    jp nz, fail

    scf
    ld a, 0x25
    dw 0x9ddd ; sbc ixl     ; y3
    cp 0x00
    jp nz, fail

    ld a, 0xa9
    dw 0xa5dd ; and ixl     ; y4
    cp 0x20
    jp nz, fail

    ld a, 0xa1
    dw 0xaddd ; xor ixl     ; y6
    cp 0x85
    jp nz, fail

    ld a, 0xa1
    dw 0xb5dd ; or ixl      ; y6
    cp 0xa5
    jp nz, fail

    ld a, 0x24
    dw 0xbddd ; cp ixl      ; y7
    jp nz, fail

; z6
    ld ix, 0xf000
    ld hl, 0xf000
    ld (hl), 0x11
    inc hl
    ld (hl), 0x22
    inc hl
    ld (hl), 0x33
    inc hl
    ld (hl), 0x44
    inc hl
    ld (hl), 0x55
    inc hl
    ld (hl), 0x66
    inc hl
    ld (hl), 0x77
    inc hl
    ld (hl), 0x88

    ld a, 0x12
    add a, (ix+0)           ; y0
    cp 0x23
    jp nz, fail

    scf
    ld a, 0x13
    adc a, (ix+1)           ; y1
    cp 0x36
    jp nz, fail

    ld a, 0x44
    sub a, (ix+2)           ; y2
    cp 0x11
    jp nz, fail

    scf
    ld a, 0x55
    sbc a, (ix+3)           ; y3
    cp 0x10
    jp nz, fail

    ld a, 0xff
    and (ix+4)              ; y4
    cp 0x55
    jp nz, fail

    ld a, 0x64
    xor (ix+5)              ; y5
    cp 0x02
    jp nz, fail

    ld a, 0x00
    or (ix+6)               ; y6
    cp 0x77
    jp nz, fail

    ld a, 0x88
    cp (ix+7)               ; y7
    jp nz, fail

; x3

; z1
    ld ix, 0xffff
    ld hl, 0x1234
    push hl
    pop ix                  ; y4
    ld a, 0x12
    dw 0xbcdd ; cp ixh
    jp nz, fail
    ld a, 0x34
    dw 0xbddd ; cp ixĺ
    jp nz, fail

    ld ix, skip             ; y5
    jp (ix)
    jp fail
    skip:

    ld bc, 0xbbcc
    ld hl, 0x4411
    push bc
    ld ix, 0x0000
    add ix, sp
    push hl
    ld sp, ix               ; y7
    pop hl
    ld a, h
    cp 0xbb
    jp nz, fail
    ld a, l
    cp 0xcc
    jp nz, fail

    ld ix, 0x2421
    ld bc, 0xbbcc
    push bc
    ex (sp), ix             ; z3, y4
    push ix                 ; z5, y4
    pop hl
    ld a, h
    cp 0xbb
    jp nz, fail
    ld a, l
    cp 0xcc
    jp nz, fail
    pop hl
    ld a, h
    cp 0x24
    jp nz, fail
    ld a,l
    cp 0x21
    jp nz, fail

success:
    ld a, 0xcc
    halt
fail:
    ld a, 0xee
    halt
