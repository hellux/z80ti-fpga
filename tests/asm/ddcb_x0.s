org 0x9d95

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

success:
    ld a, 0xcc
    halt
fail:
    ld a, 0xee
    halt
