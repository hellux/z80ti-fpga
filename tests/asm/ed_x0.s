org 0x9d95

; z7
    ei
    ld a, 0xfe
    ld i, a                 ; y0
    ld a, 0x00
    ld a, i                 ; y2
    jp p, fail
    jp z, fail
    jp po, fail
    cp 0xfe
    jp nz, fail

    di
    ld a, 0x3c
    ld r, a                 ; y1
    ld a, 0x00
    ld a, r                 ; y3
    jp m, fail
    jp z, fail
    jp pe, fail
    cp 0x3c
    jp nz, fail

    ld a, 0x84
    ld (hl), 0x20
    scf
    rrd                     ; y4
    jp p, fail
    jp z, fail
    jp pe, fail
    jp nc, fail
    cp 0x80
    jr nz, fail
    ld a, (hl)
    cp 0x42
    jr nz, fail

    ld hl, 0xf001
    ld a, 0x7a
    ld (hl), 0x31
    scf
    ccf
    rld                     ; y5
    jp m, fail
    jp z, fail
    jp pe, fail
    jp c, fail
    cp 0x73
    jr nz, fail
    ld a, (hl)
    cp 0x1a
    jr nz, fail


success:
    ld a, 0xcc
    halt
fail:
    ld a, 0xee
    halt
