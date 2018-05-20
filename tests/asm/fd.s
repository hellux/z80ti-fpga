org 0x9d95
; total: 830 us

; x0

; z0 noni

; z1

    ld iy, 0x89ab           ; q0, p2
    add iy, iy              ; q1, p0
    dw 0x7cfd ; ld a, iyh
    cp 0x13
    jp nz, fail
    dw 0x7dfd ; ld a, iyl
    cp 0x56
    jp nz, fail

    ld bc, 0x0123
    add iy, bc              ; q1, p1
    dw 0x7cfd ; ld a, iyh
    cp 0x14
    jp nz, fail
    dw 0x7dfd ; ld a, iyl
    cp 0x79
    jp nz, fail

    ld de, 0x4567
    add iy, de              ; q1, p2
    dw 0x7cfd ; ld a, iyh
    cp 0x59
    jp nz, fail
    dw 0x7dfd ; ld a, iyl
    cp 0xe0
    jp nz, fail

    ld hl, 0x000
    add hl, sp
    ld sp, 0xcdef
    add iy, sp              ; q1, p3
    dw 0x7cfd ; ld a, iyh
    cp 0x27
    jp nz, fail
    dw 0x7dfd ; ld a, iyl
    cp 0xcf
    jp nz, fail
    ld sp, hl

; z2 
    ld (0xf000), iy         ; q0, p2
    ld a, (0xf001)
    cp 0x27
    jp nz, fail
    ld a, (0xf000)
    cp 0xcf
    jp nz, fail

    ld iy, 0x0000
    ld iy, (0xf000)         ; q1, p2
    dw 0x7cfd ; ld a, iyh
    cp 0x27
    jp nz, fail
    dw 0x7dfd ; ld a, iyl
    cp 0xcf
    jp nz, fail

; z3
    ld iy, 0x27ff
    inc iy                  ; q0; p2
    dw 0x7cfd ; ld a, iyh
    cp 0x28
    jp nz, fail
    dw 0x7dfd ; ld a, iyl
    cp 0x00
    jp nz, fail

    dec iy                  ; q1; p2
    dw 0x7cfd ; ld a, iyh
    cp 0x27
    jp nz, fail
    dw 0x7dfd ; ld a, iyl
    cp 0xff
    jp nz, fail

; z4
    dw 0x24fd ; inc iyh     ; y4
    dw 0x7cfd ; ld a, iyh
    cp 0x28
    jp nz, fail
    dw 0x7dfd ; ld a, iyl
    cp 0xff
    jp nz, fail

    dw 0x2cfd ; inc iyl     ; y5
    dw 0x7cfd ; ld a, iyh
    cp 0x28
    jp nz, fail
    dw 0x7dfd ; ld a, iyl
    cp 0x00
    jp nz, fail
    
    ld iy, 0xf000
    ld a, 0x05
    ld (0xf009), a
    inc (iy+9)              ; y5
    ld a, (0xf009)
    cp 0x06
    jp nz, fail

; z5
    dw 0x25fd ; dec iyh     ; y4
    dw 0x7cfd ; ld a, iyh
    cp 0xef
    jp nz, fail
    dw 0x7dfd ; ld a, iyl
    cp 0x00
    jp nz, fail

    dw 0x2dfd ; dec iyl     ; y5
    dw 0x7cfd ; ld a, iyh
    cp 0xef
    jp nz, fail
    dw 0x7dfd ; ld a, iyl
    cp 0xff
    jp nz, fail
    
    ld iy, 0xf000
    dec (iy+9)              ; y5
    ld a, (0xf009)
    cp 0x05
    jp nz, fail

; z6
    ld iyh, 0x24            ; y4
    dw 0x7cfd ; ld a, iyh
    cp 0x24
    jp nz, fail

    ld iyl, 0xe3            ; y5
    dw 0x7dfd ; ld a, iyl
    cp 0xe3
    jp nz, fail

    ld iy, 0xf000           ; y6
    ld (iy+9), 0x9a
    ld a, (0xf009)
    cp 0x9a
    jp nz, fail

; z7 noni

; x1

; y4
    ld b, 0xbb
    ld iyh, b               ; z0
    dw 0x7cfd ; ld a, iyh
    cp 0xbb
    jp nz, fail

    ld c, 0xcc
    ld iyh, c               ; z1
    dw 0x7cfd ; ld a, iyh
    cp 0xcc
    jp nz, fail

    ld d, 0xdd
    ld iyh, d               ; z2
    dw 0x7cfd ; ld a, iyh
    cp 0xdd
    jp nz, fail

    ld e, 0xee
    ld iyh, e               ; z3
    dw 0x7cfd ; ld a, iyh
    cp 0xee
    jp nz, fail

    ld h, 0x44
    ld iyh, iyh             ; z4
    dw 0x7cfd ; ld a, iyh
    cp 0xee
    jp nz, fail
    ld a, h
    cp 0x44
    jp nz, fail

    ld iy, 0x2421
    ld iyh, iyl             ; z5
    dw 0x7cfd ; ld a, iyh
    cp 0x21
    jp nz, fail
    dw 0x7dfd ; ld a, iyl
    cp 0x21
    jp nz, fail
                            ; z6 above

    ld a, 0xaa              ; z7
    ld iyh, a
    dw 0x7cfd ; ld a, iyh
    cp 0xaa
    jp nz, fail

; y5
    ld iyl, b               ; z0
    dw 0x7dfd ; ld a, iyl
    cp 0xbb
    jp nz, fail

    ld iyl, c               ; z1
    dw 0x7dfd ; ld a, iyl
    cp 0xcc
    jp nz, fail

    ld iyl, d               ; z2
    dw 0x7dfd ; ld a, iyl
    cp 0xdd
    jp nz, fail

    ld iyl, e               ; z3
    dw 0x7dfd ; ld a, iyl
    cp 0xee
    jp nz, fail

    ld iy, 0x2421
    ld iyl, iyh             ; z4
    dw 0x7dfd ; ld a, iyl
    cp 0x24
    jp nz, fail
    
    ld l, 0x11
    ld iyl, iyl             ; z5
    dw 0x7dfd ; ld a, iyl
    cp 0x24
    jp nz, fail
    ld a, l
    cp 0x11
    jp nz, fail
                            ; z6 above

    ld a, 0xaa
    ld iyl, a               ; z7
    dw 0x7dfd ; ld a, iyl
    cp 0xaa
    jp nz, fail

; z4
    ld iy, 0x2421
    ld b, iyh               ; y0
    ld a, b
    cp 0x24
    jp nz, fail
    ld c, iyh               ; y1
    ld a, c
    cp 0x24
    jp nz, fail
    ld d, iyh               ; y2
    ld a, d
    cp 0x24
    jp nz, fail
    ld e, iyh               ; y3
    ld a, e
    cp 0x24
    jp nz, fail
                            ; y4 above
                            ; y5 above
                            ; y6 above
    ld a, 0x00
    dw 0x7cfd ; ld a, iyh   ; y7
    cp 0x24
    jp nz, fail

; y6
    ld iy, 0xf010

    ld b, 0xbb
    ld (iy+0), b            ; z0
    ld (0xf000), a
    cp 0xbb

    ld c, 0xbb
    ld (iy+1), c            ; z1
    ld (0xf001), a
    cp 0xcc

    ld d, 0xdd
    ld (iy+2), d            ; z2
    ld (0xf002), a
    cp 0xdd

    ld e, 0xee
    ld (iy+3), e            ; z3
    ld (0xf003), a
    cp 0xee

    ld h, 0x44
    ld (iy+4), h            ; z4
    ld (0xf004), a
    cp 0x44

    ld l, 0x11
    ld (iy+5), l            ; z5
    ld (0xf005), a
    cp 0x11

    ld a, 0xaa
    ld (iy+6), a            ; z7
    ld (0xf006), a
    cp 0xaa

; z5
    ld iy, 0x2421
    ld b, iyl               ; y0
    ld a, b
    cp 0x21
    jp nz, fail
    ld c, iyl               ; y1
    ld a, c
    cp 0x21
    jp nz, fail
    ld d, iyl               ; y2
    ld a, d
    cp 0x21
    jp nz, fail
    ld e, iyl               ; y3
    ld a, e
    cp 0x21
    jp nz, fail
                            ; y4 above
                            ; y5 above
                            ; y6 above
    ld a, 0x00
    dw 0x7dfd ; ld a, iyl   ; y7
    cp 0x21
    jp nz, fail

; z6
    ld hl, 0xf000
    ld iy, 0xf000
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
    ld b, (iy+0)            ; y0
    ld a, b
    cp 0xbb
    jp nz, fail
    ld c, (iy+1)            ; y1
    ld a, c
    cp 0xcc
    jp nz, fail
    ld d, (iy+2)            ; y2
    ld a, d
    cp 0xdd
    jp nz, fail
    ld e, (iy+3)            ; y3
    ld a, e
    cp 0xee
    jp nz, fail
    ld h, (iy+4)            ; y4
    ld a, h
    cp 0x44
    jp nz, fail
    ld l, (iy+5)            ; y5
    ld a, l
    cp 0x11
    jp nz, fail
                            ; y6 noni
    ld a, (iy+6)            ; y7
    cp 0xaa
    jp nz, fail

; z7 noni

; x2

; z0 noni
; z1 noni
; z2 noni
; z3 noni

; z4
    ld iy, 0x2421

    ld a, 0x12
    dw 0x84fd ; add a, iyh  ; y0
    cp 0x36
    jp nz, fail

    scf
    ld a, 0x12
    dw 0x8cfd ; adc a, iyh  ; y1
    cp 0x37
    jp nz, fail

    ld a, 0x25
    dw 0x94fd ; sub iyh     ; y2
    cp 0x01
    jp nz, fail

    scf
    ld a, 0x25
    dw 0x9cfd ; sbc iyh     ; y3
    cp 0x00
    jp nz, fail

    ld a, 0xa9
    dw 0xa4fd ; and iyh     ; y4
    cp 0x20
    jp nz, fail

    ld a, 0xa1
    dw 0xacfd ; xor iyh     ; y6
    cp 0x85
    jp nz, fail

    ld a, 0xa1
    dw 0xb4fd ; or iyh      ; y6
    cp 0xa5
    jp nz, fail

    ld a, 0x24
    dw 0xbcfd ; cp iyh      ; y7
    jp nz, fail

; z5
    ld iy, 0x2124

    ld a, 0x12
    dw 0x85fd ; add a, iyl  ; y0
    cp 0x36
    jp nz, fail

    scf
    ld a, 0x12
    dw 0x8dfd ; adc a, iyl  ; y1
    cp 0x37
    jp nz, fail

    ld a, 0x25
    dw 0x95fd ; sub iyl     ; y2
    cp 0x01
    jp nz, fail

    scf
    ld a, 0x25
    dw 0x9dfd ; sbc iyl     ; y3
    cp 0x00
    jp nz, fail

    ld a, 0xa9
    dw 0xa5fd ; and iyl     ; y4
    cp 0x20
    jp nz, fail

    ld a, 0xa1
    dw 0xadfd ; xor iyl     ; y6
    cp 0x85
    jp nz, fail

    ld a, 0xa1
    dw 0xb5fd ; or iyl      ; y6
    cp 0xa5
    jp nz, fail

    ld a, 0x24
    dw 0xbdfd ; cp iyl      ; y7
    jp nz, fail

; z6
    ld iy, 0xf000
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
    add a, (iy+0)           ; y0
    cp 0x23
    jp nz, fail

    scf
    ld a, 0x13
    adc a, (iy+1)           ; y1
    cp 0x36
    jp nz, fail

    ld a, 0x44
    sub a, (iy+2)           ; y2
    cp 0x11
    jp nz, fail

    scf
    ld a, 0x55
    sbc a, (iy+3)           ; y3
    cp 0x10
    jp nz, fail

    ld a, 0xff
    and (iy+4)              ; y4
    cp 0x55
    jp nz, fail

    ld a, 0x64
    xor (iy+5)              ; y5
    cp 0x02
    jp nz, fail

    ld a, 0x00
    or (iy+6)               ; y6
    cp 0x77
    jp nz, fail

    ld a, 0x88
    cp (iy+7)               ; y7
    jp nz, fail

; x3

; z1
    ld iy, 0xffff
    ld hl, 0x1234
    push hl
    pop iy                  ; y4
    ld a, 0x12
    dw 0xbcfd ; cp iyh
    jp nz, fail
    ld a, 0x34
    dw 0xbdfd ; cp iyĺ
    jp nz, fail

    ld iy, skip             ; y5
    jp (iy)
    jp fail
    skip:

    ld bc, 0xbbcc
    ld hl, 0x4411
    push bc
    ld iy, 0x0000
    add iy, sp
    push hl
    ld sp, iy               ; y7
    pop hl
    ld a, h
    cp 0xbb
    jp nz, fail
    ld a, l
    cp 0xcc
    jp nz, fail

    ld iy, 0x2421
    ld bc, 0xbbcc
    push bc
    ex (sp), iy             ; z3, y4
    push iy                 ; z5, y4
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
