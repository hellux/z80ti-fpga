org 0x0000 ; use absolute addresses
aux_addr: equ 0xf000

    im 1
    ld a, 0x40 ; page B to RAM 0
    out (0x07), a
    jp aux_addr
