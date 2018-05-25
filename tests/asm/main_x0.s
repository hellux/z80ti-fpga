org 0x9d95

; z2
    ld a, 0xd3
    ld bc, 0xf000
    ld (bc), a              ; y0
    ld a, 0x00
    ld a, (0xf000)          ; y7
    cp 0xd3
    jp nz, fail

    ld a, 0x00
    ld a, (bc)              ; y1
    cp 0xd3
    jp nz, fail

    ld a, 0xdb
    ld de, 0xf001
    ld (de), a              ; y2
    ld a, 0x00
    ld a, (0xf001)
    cp 0xdb
    jp nz, fail

    ld a, 0x00
    ld a, (de)              ; y3
    cp 0xdb
    jp nz, fail

    ld hl, 0x4411
    ld (0xf002), hl         ; y4
    ld a, (0xf002)
    cp 0x11
    jp nz, fail
    ld a, (0xf003)
    cp 0x44
    jp nz, fail

success:
    ld a, 0xcc
    halt
fail:
    ld a, 0xee
    halt
