org 0x0000
app_start: equ 0x9d95

    ld a, 0x76  ; mem mode to 0
    out (0x04), a
    ld a, 0x0f  ; page a to rom 0f 
    out (0x06), a
    ld a, 0x41  ; page b to ram 01
    out (0x07), a

start:
    call app_start
    jr start
