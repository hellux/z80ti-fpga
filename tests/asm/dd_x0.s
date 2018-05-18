org 0x9d95

; z0 noni

; z1
    ld bc, 0x0123
    ld de, 0x4567
    ld ix, 0x89ab           ; q0, p2
    ld sp, 0xcdef

    add ix, ix              ; q1, p0
    dw 0x7cdd ; ld a, ixh
    cp 0x13
    jp nz, fail
    dw 0x7ddd ; ld a, ixl
    cp 0x56
    jp nz, fail

    add ix, bc              ; q1, p1
    dw 0x7cdd ; ld a, ixh
    cp 0x14
    jp nz, fail
    dw 0x7ddd ; ld a, ixl
    cp 0x79
    jp nz, fail

    add ix, de              ; q1, p2
    dw 0x7cdd ; ld a, ixh
    cp 0x59
    jp nz, fail
    dw 0x7ddd ; ld a, ixl
    cp 0xe0
    jp nz, fail

    add ix, sp              ; q1, p3
    dw 0x7cdd ; ld a, ixh
    cp 0x27
    jp nz, fail
    dw 0x7ddd ; ld a, ixl
    cp 0xcf
    jp nz, fail

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

success:
    ld a, 0xcc
    halt
fail:
    ld a, 0xee
    halt
