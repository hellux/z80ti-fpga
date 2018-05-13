org 0x9d95

;ldi manual exampl
;before:
;   0000: 88
;   0010: 66
;   hl: 0000
;   de: 0010
;   bc: 0007
;after:
;   0000: 88
;   0010: 88
;   hl: 0001
;   de: 0011
;   bc: 0006
ldi1_setup:
    ld a, 0
    add a, 0x01 ; P, NZ
    scf
    ccf ; NC
    ld a, 0x88
    ld (0x0000), a
    ld a, 0x66
    ld (0x0010), a
    ld a, 0x34
    ld hl, 0x0000
    ld de, 0x0010
    ld bc, 0x0007

    ldi 

ldi1_test:
    jp m, fail
    jp z, fail
    jp c, fail
    jp po, fail
    cp 0x34
    jp nz, fail
    ld a, h
    cp 0x00
    jp nz, fail
    ld a, l
    cp 0x01
    jp nz, fail
    ld a, d
    cp 0x00
    jp nz, fail
    ld a, e
    cp 0x11
    jp nz, fail
    ld a, b
    cp 0x00
    jp nz, fail
    ld a, c
    cp 0x06
    jp nz, fail

;ldir manual exampl
;before:
;   0000: 88
;   0001: 36
;   0002: a5
;   0010: 66
;   0011: 59
;   0012: c5
;   hl: 0000
;   de: 0010
;   bc: 0003
;after:
;   0000: 88
;   0001: 36
;   0002: a5
;   0010: 88
;   0011: 36
;   0012: a5
;   hl: 0003
;   de: 0013
;   bc: 0000
ldir1_setup:
    ld a, 0x02
    add a, 0x02 ; NZ; p
    scf; C
    ld a, 0x88
    ld (0x0000), a
    ld a, 0x36
    ld (0x0001), a
    ld a, 0xa5
    ld (0x0002), a
    ld a, 0x66
    ld (0x0010), a
    ld a, 0x59
    ld (0x0011), a
    ld a, 0xc5
    ld (0x0012), a
    ld hl, 0x0000
    ld de, 0x0010
    ld bc, 0x0003

    ldir

ldir1_test:
    jp m, fail
    jp nc, fail
    jp z, fail
    jp pe, fail
    ld a, h
    cp 0x00
    jp nz, fail
    ld a, l
    cp 0x03
    jp nz, fail
    ld a, d
    cp 0x00
    jp nz, fail
    ld a, e
    cp 0x13
    jp nz, fail
    ld a, b
    cp 0x00
    jp nz, fail
    ld a, c
    cp 0x00
    jp nz, fail

; cpi manual example
; before:
;   0000: 3b
;   a: 3b
;   hl: 0000
;   bc: 0001
; after:
;   hl: 0001
;   bc: 0000
;   Z, PO

cpi1_setup:
    ld a, 0x3b
    ld (0x000), a
    ld hl, 0x0000
    ld bc, 0x0001

    cpi

cpi1_test:
    jp nz, fail
    jp pe, fail
    cp 0x3b
    jp nz, fail
    ld a, h
    cp 0x00
    jp nz, fail
    ld a, l
    cp 0x01
    jp nz, fail
    ld a, b
    cp 0x00
    jp nz, fail
    ld a, c
    cp 0x00
    jp nz, fail

; cpir manual example
; before:
;   0000: 52
;   0001: 00
;   0002: f3
;   a: f3
;   hl: 0000
;   bc: 0007
; after:
;   hl: 0003
;   bc: 0004
;   Z, PE
cpir1_setup:
    ld a, 0x00
    add a, 0x01 ; NZ, PO
    ld a, 0x52
    ld (0x0000), a
    ld a, 0x00
    ld (0x0001), a
    ld a, 0xf3
    ld (0x0002), a

    ld a, 0xf3
    ld bc, 0x0007
    ld hl, 0x0000

    cpir

    cpir1_test:
    jp nz, fail
    jp po, fail
    cp 0xf3
    jp nz, fail
    ld a, h
    cp 0x00
    jp nz, fail
    ld a, l
    cp 0x03
    jp nz, fail
    ld a, b
    cp 0x00
    jp nz, fail
    ld a, c
    cp 0x04
    jp nz, fail

    ld a, 0x00
    add a, 0x00 ; Z, PE

; cpir manual example, but without match
; before:
;   0000: 52
;   0001: 00
;   0002: f3
;   0003: f5
;   0004: f6
;   0005: f7
;   0006: f8
;   a: f4
;   hl: 0000
;   bc: 0007
; after:
;   hl: 0007
;   bc: 0000
;   Z, PE
cpir2_setup:
    ld a, 0x52
    ld (0x0000), a
    ld a, 0x00
    ld (0x0001), a
    ld a, 0xf3
    ld (0x0002), a

    ld a, 0xf4
    ld bc, 0x0007
    ld hl, 0x0000

    cpir

cpir2_test:
    jp z, fail
    jp pe, fail
    cp 0xf4
    jp nz, fail
    ld a, h
    cp 0x00
    jp nz, fail
    ld a, l
    cp 0x07
    jp nz, fail
    ld a, b
    cp 0x00
    jp nz, fail
    ld a, c
    cp 0x00
    jp nz, fail

success:
    ld a, 0xcc
    halt

fail:
    ld a, 0xee
    halt
