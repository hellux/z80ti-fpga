org 0x9d95

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

; z7 noni

success:
    ld a, 0xcc
    halt
fail:
    ld a, 0xee
    halt
