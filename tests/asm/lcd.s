ld c, 0x10
ld a, 0x0   ; 6-bit
call wlcd
out (c), a
ld a, 0x03   ; power on
call wlcd
out (c), a   
ld a, 0x04   ; x dec
call wlcd
out (c), a
ld a, 0xff

call wlcd
out (0x11), a
call wlcd
out (0x11), a
call wlcd
out (0x11), a
call wlcd
out (0x11), a
call wlcd
out (0x11), a
call wlcd
out (0x11), a

ld a, 0x01
call wlcd
out (c), a  ; 8-bit
ld a, 0x07
call wlcd
out (c), a  ; y inc

call wlcd
out (0x11), a
call wlcd
out (0x11), a
call wlcd
out (0x11), a
call wlcd
out (0x11), a
call wlcd
out (0x11), a
halt

wlcd:
in a, (0x10)
bit 7, a
jr nz, wlcd
ret
