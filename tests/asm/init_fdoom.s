org 0x0000 ; use absolute addresses

aux_addr: equ 0xf000 ; jump here to setup memory mapping

pc_high: equ 0xa1
pc_low: equ 0x4e

im 1
ld a, 0x40 ; page B to RAM 0
out (0x07), a

; load instructions to RAM page
ld hl, aux_addr
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
; ld a, 0x07 ; page A to ROM 0f
ld (hl), 0x3e
inc hl
ld (hl), 0x0f
inc hl
; out (0x06), a
ld (hl), 0xd3
inc hl
ld (hl), 0x06
inc hl
; ld a, 0x07 ; page B to RAM 01
ld (hl), 0x3e
inc hl
ld (hl), 0x41
inc hl
; out (0x07), a
ld (hl), 0xd3
inc hl
ld (hl), 0x07
inc hl
; call 0x9dc6
ld (hl), 0xcd
inc hl
ld (hl), pc_low
inc hl
ld (hl), pc_high
; jr to above call
inc hl
ld (hl), 0x18
inc hl
ld (hl), 0xfb

jp aux_addr
