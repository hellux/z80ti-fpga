ld a, 0x0f
ld (0x35), a
inc ix
inc ix
inc ix
inc ix
inc ix
rlc (ix+0x30)
set 0, (ix+0x30)
res 4, (ix+0x30)
halt
