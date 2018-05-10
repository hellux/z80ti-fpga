org 0x0000
im 1

ld a, 0x40 ; page B to RAM 0
out (0x07), a

; load instructions to RAM page
ld hl, 0xc000
; ld a, 0x76 ; mem mode to 0
ld (hl), 0x3e
inc hl
ld (hl), 0x76
inc hl
; out (0x04), a
ld (hl), 0xd3
inc hl
ld (hl), 0x04
inc hl
; ld a, 0x07 ; page A to ROM 07 
ld (hl), 0x3e
inc hl
ld (hl), 0x07
inc hl
; out (0x06), a
ld (hl), 0xd3
inc hl
ld (hl), 0x06
inc hl
; ld a, 0x07 ; page B to RAM 1
ld (hl), 0x3e
inc hl
ld (hl), 0x41
inc hl
; out (0x07), a
ld (hl), 0xd3
inc hl
ld (hl), 0x07
inc hl
; jp 0x9d95
ld (hl), 0xc3
inc hl
ld (hl), 0x95
inc hl
ld (hl), 0x9d

jp 0xc000
