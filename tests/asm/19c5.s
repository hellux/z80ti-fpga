org 0x9d95

    ld a, 0x5d
    ld (0xf030), a
    ld (0x8481), a
    ld hl, 0x8481

    push hl
    ld hl, 0xf030
    ld a, (hl)
    ld d, a
    ld bc, 0x0008
    xor a
    cpir
    pop hl
    ld a, 0x08
    halt
