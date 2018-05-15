org 0x9d95

pre_a: equ 0xaa
pre_f: equ 0xff
pre_b: equ 0xbb
pre_c: equ 0xcc
pre_d: equ 0xdd
pre_e: equ 0xee
pre_h: equ 0x44
pre_l: equ 0x11
pre_ixh: equ 0x02
pre_ixl: equ 0x12
pre_iyh: equ 0x05
pre_iyl: equ 0x15

post_a: equ pre_a
post_f: equ pre_f
post_b: equ pre_b
post_c: equ pre_c
post_d: equ pre_d
post_e: equ pre_e
post_h: equ pre_h
post_l: equ pre_l
post_ixh: equ pre_ixh
post_ixl: equ pre_ixl
post_iyh: equ pre_iyh
post_iyl: equ pre_iyl

pre:
    ld a, pre_ixh
    ld ixh, a
    ld a, pre_ixl
    ld ixl, a
    ld a, pre_iyh
    ld iyh, a
    ld a, pre_iyl
    ld iyl, a
    ld h, pre_a
    ld l, pre_f
    push hl
    pop af
    ld b, pre_b
    ld c, pre_c
    ld d, pre_d
    ld e, pre_e
    ld h, pre_h
    ld l, pre_l

; op

test:
; cp af
    push hl
    push af
    pop hl
    ld a, h
    cp post_a
    jp nz, fail
    ld a, l
    cp post_f
    jp nz, fail
    pop hl
; cp bc
    ld a, post_b
    cp b
    jp nz, fail
    ld a, post_c
    cp c
    jp nz, fail
; cp de
    ld a, post_d
    cp d
    jp nz, fail
    ld a, post_e
    cp e 
    jp nz, fail
; cp hl
    ld a, h
    cp post_h
    jp nz, fail
    ld a, l
    cp post_l
    jp nz, fail
; cp ix
    ; ld a, ixh
    db 0xdd
    db 0x7c
    cp post_ixh
    jp nz, fail
    ; ld a, ixl
    db 0xdd
    db 0x7d
    cp post_ixl
    jp nz, fail
; cp iy
    ; ld a, iyh
    db 0xfd
    db 0x7c
    cp post_iyh
    jp nz, fail
    ; ld a, iyl
    db 0xfd
    db 0x7d
    cp post_iyl
    jp nz, fail

success:
    ld a, 0xcc
    halt
fail:
    ld a, 0xee 
    halt
