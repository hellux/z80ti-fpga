org 0x9d95

; acd 0h, 0h
ld h, 0x00
ld l, 0x44
push hl
pop af

adc a, 0x00
; 0040
jp m, fail
jp nz, fail
jp pe, fail
jp c, fail

daa
; 0044
jp m, fail
jp nz, fail
jp po, fail
jp c, fail
cp 0x00
jp nz, fail

; add 45h, 16h
ld h, 0x45
ld l, 0x44
push hl
pop af
ld e, 0x16

add a, e
; 5b08
jp m, fail
jp z, fail
jp pe, fail
jp c, fail

daa
; 6130
jp m, fail
jp z, fail
jp pe, fail
jp c, fail
cp 0x61
jp nz, fail

; adc 80h, a3h
ld h, 0x80
ld l, 0x30
push hl
pop af
ld d, 0xa3

adc a, d
; 2325
jp m, fail
jp z, fail
jp po, fail
jp nc, fail

daa
; 8381
jp p, fail
jp z, fail
jp pe, fail
jp nc, fail
cp 0x83
jp nz, fail

; sbc 0h, 6h
ld h, 0x00
ld l, 0xbb
push hl
pop af
ld hl, 0x0000
ld (hl), 0x06

sbc a, (hl)
; f9bb
jp p, fail
jp z, fail
jp pe, fail
jp nc, fail

daa
; 9387
jp p, fail
jp z, fail
jp po, fail
jp nc, fail
cp 0x93
jp nz, fail

; sbc 37h, 62h
ld h, 0x37
ld l, 0x46
push hl
pop af
ld l, 0x62

sbc a, l
; d583
jp p, fail
jp z, fail
jp pe, fail
jp nc, fail

daa
; 7523
jp m, fail
jp z, fail
jp pe, fail
jp nc, fail
cp 0x75
jp nz, fail

success:
ld a, 0xcc
halt

fail:
ld a, 0xee
halt
