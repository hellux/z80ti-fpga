scf
ld a, 0x00
adc a, 0x7f
push af
pop hl
bit 4, l
call z, fail

scf
ld a, 0x7f
adc a, 0x00
push af
pop hl
bit 4, l
call z, fail

scf
ld a, 0x00
adc a, 0xff
push af
pop hl
bit 4, l
call z, fail

scf
ld a, 0x7f
adc a, 0x7f
push af
pop hl
bit 4, l
call z, fail

ld hl, 0x2123
ld bc, 0x1242
add hl, bc
push af
pop hl
bit 4, l
call nz, fail

ld hl, 0x0fff
ld bc, 0x0000
scf
adc hl, bc
push af
pop hl
bit 4, l
call z, fail

ld hl, 0x00ff
ld bc, 0x0000
scf
adc hl, bc
push af
pop hl
bit 4, l
call nz, fail

success:
ld a, 0xcc
halt

fail:
pop bc
ld e, 0xee
halt
