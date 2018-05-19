org 0x9d95

; z1
    ld ix, 0xffff
    ld hl, 0x1234
    push hl
    pop ix                  ; y4
    ld a, 0x12
    dw 0xbcdd ; cp ixh
    jp nz, fail
    ld a, 0x34
    dw 0xbddd ; cp ixĺ
    jp nz, fail

    ld ix, skip             ; y5
    jp (ix)
    jp fail
    skip:

    ld bc, 0xbbcc
    ld hl, 0x4411
    push bc
    ld ix, 0x0000
    add ix, sp
    push hl
    ld sp, ix               ; y7
    pop hl
    ld a, h
    cp 0xbb
    jp nz, fail
    ld a, l
    cp 0xcc
    jp nz, fail

    ld ix, 0x2421
    ld bc, 0xbbcc
    push bc
    ex (sp), ix             ; z3, y4
    push ix                 ; z5, y4
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
