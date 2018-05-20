org 0x9d95

; acd 0h, 0h
ld h, 0x00
ld l, 0x44
push hl
pop af

adc a, 0x00
; 0040
call m, fail
call nz, fail
call pe, fail
call c, fail

daa
; 0044
call m, fail
call nz, fail
call po, fail
call c, fail
cp 0x00
call nz, fail

; add 45h, 16h
ld h, 0x45
ld l, 0x44
push hl
pop af
ld e, 0x16

add a, e
; 5b08
call m, fail
call z, fail
call pe, fail
call c, fail

daa
; 6130
call m, fail
call z, fail
call pe, fail
call c, fail
cp 0x61
call nz, fail

; adc 80h, a3h
ld h, 0x80
ld l, 0x30
push hl
pop af
ld d, 0xa3

adc a, d
; 2325
call m, fail
call z, fail
call po, fail
call nc, fail

daa
; 8381
call p, fail
call z, fail
call pe, fail
call nc, fail
cp 0x83
call nz, fail

; sbc 0h, 6h
ld h, 0x00
ld l, 0xbb
push hl
pop af
ld hl, 0xf000
ld (hl), 0x06

sbc a, (hl)
; f9bb
call p, fail
call z, fail
call pe, fail
call nc, fail

daa
; 9387
call p, fail
call z, fail
call po, fail
call nc, fail
cp 0x93
call nz, fail

; sbc 37h, 62h
ld h, 0x37
ld l, 0x46
push hl
pop af
ld l, 0x62

sbc a, l
; d583
call p, fail
call z, fail
call pe, fail
call nc, fail

daa
; 7523
call m, fail
call z, fail
call pe, fail
call nc, fail
cp 0x75
call nz, fail

xor a
scf
daa
call m, fail
call z, fail
call po, fail
call nc, fail

success:
ld a, 0xcc
halt

fail:
pop bc
ld e, 0xee
halt
