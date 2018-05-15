org 0x9d95

setup:
    ld de, 0x1234
    ld hl, 0x5678
    exx
    ld de, 0x4321
    ld hl, 0x8765

    ex de, hl

test:
    ld a, d
    cp 0x87
    jp nz, fail
    
    ld a, e
    cp 0x65
    jp nz, fail

    ld a, h
    cp 0x43
    jp nz, fail

    ld a, l
    cp 0x21
    jp nz, fail

    exx

    ld a, d
    cp 0x12
    jp nz, fail
    
    ld a, e
    cp 0x34
    jp nz, fail

    ld a, h
    cp 0x56
    jp nz, fail

    ld a, l
    cp 0x78
    jp nz, fail

success:
    ld a, 0xcc
    halt

fail:
    ld a, 0xee
    halt
