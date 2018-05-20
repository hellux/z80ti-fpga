org 0x9d95
; 430 us

; x0
    ld ix, 0xf000

; z6
    ld a, 0x88
    ld (0xf000), a
    rlc (ix+0)              ; y0
    jp nc, fail
    ld a, (0xf000)
    cp 0x11
    jp nz, fail

    ld a, 0x31
    ld (0xf001), a
    rrc (ix+1)              ; y1
    jp nc, fail
    ld a, (0xf001)
    cp 0x98
    jp nz, fail

    scf
    ccf
    ld a, 0x8f
    ld (0xf002), a
    rl (ix+2)               ; y2
    jp nc, fail
    ld a, (0xf002)
    cp 0x1e
    jp nz, fail

    scf
    ccf
    ld a, 0xdd
    ld (0xf003), a
    rr (ix+3)               ; y3
    jp nc, fail
    ld a, (0xf003)
    cp 0x6e
    jp nz, fail

    scf
    ccf
    ld a, 0xb1
    ld (0xf004), a
    sla (ix+4)              ; y4
    jp nc, fail
    ld a, (0xf004)
    cp 0x62
    jp nz, fail

    scf
    ld a, 0xb8
    ld (0xf005), a
    sra (ix+5)              ; y5
    jp c, fail
    ld a, (0xf005)
    cp 0xdc
    jp nz, fail

    scf
    ccf
    ld a, 0xb9
    ld (0xf005), a
    sra (ix+5)              ; y5
    jp nc, fail
    ld a, (0xf005)
    cp 0xdc
    jp nz, fail

    scf
    ccf
    ld a, 0xb1
    ld (0xf006), a
    dw 0xcbdd
    dw 0x3606 ; sl1 (ix+6)  ; y6
    jp nc, fail
    ld a, (0xf006)
    cp 0x63
    jp nz, fail

    scf
    ccf
    ld a, 0x8f
    ld (0xf007), a
    srl (ix+7)              ; y7
    jp nc, fail
    ld a, (0xf007)
    cp 0x47
    jp nz, fail

; x1
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

; x2
; z6
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

; x3
; z6
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
