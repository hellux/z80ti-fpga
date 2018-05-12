org 0x9d95

ld b, 4
xor a
loop:
add a, 1 ; reset zero flag
djnz loop
jp z, fail ; assert zero flag unchanged
cp 4
jp nz, fail

scf
ex af, af'
ex de, hl
exx
ld a, 0x50
ccf
ex af, af'
jp nc, fail
cp 4
jp nz, fail
ex af, af'
jp c, fail
cp 0x50
jp nz, fail

push af
push hl
ld a, 0x34
xor a
scf
pop af
pop af
jp nz, fail
cp 0x50
jp nz, fail

success:
ld a, 0xcc
halt

fail:
ld a, 0xee
halt
