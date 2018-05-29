org 0x9d95

    ld sp, 0xffff
    ld bc, 0x1234
    push bc
    ld hl, 0x5678
    ex (sp), hl
    ld a, h
    cp 0x12
    jp nz, fail
    ld a, l
    cp 0x34
    jp nz, fail
    pop hl
    ld a, h
    cp 0x56
    jp nz, fail
    ld a, l
    cp 0x78
    jp nz, fail

    ld sp, 0xfffe
    ex (sp), hl
    ld hl, 0x0000
    add hl, sp
    ld a, h
    cp 0xff
    jp nz, fail
    ld a, l
    cp 0xfe
    jp nz, fail
    

success:
    ld a, 0xcc
    halt
fail:
    ld a, 0xee
    halt
