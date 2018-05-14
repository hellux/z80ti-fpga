org $9d95
depl_addr_high: equ 0x9d
depl_addr_low: equ 0xb9

int_jump:
    ld a, 0xc3
    ld (0x9a9a), a
    ld a, depl_addr_low
    ld (0x9a9b), a
    ld a, depl_addr_high
    ld (0x9a9c), a
ireg:
    ld a, 0x99
    ld i, a
enable_int:
    ld a, 0x0f
    out (0x03), a
    ld a, 0x00
    out (0x04), a
    im 2
    ei

    ld a, 0x00
loop:
    add a, 0x01
    jr loop

deplacement:
	exx
	push	af
	;ld	a,(compteurinterrup)
	dec	a
	;ld	(compteurinterrup),a
	;jp	nz,findep2

	;ld	hl,(xperso_v)
	;ld	(xpersovieux),hl		;sauvegarde les anciennes coordonnées du perso
	;ld	hl,(zperso_v)
	;ld	(zpersovieux),hl

findep2:
	ld	a,$08				; je sais pas si ca sert le 1er out 
	out	($03),a
	ld	a,$0F	
	out	($03),a	
		
	pop	af
	exx
	ei
	reti
