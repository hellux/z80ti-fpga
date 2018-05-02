ld a, 0x00 ; mem mode 0, max hwt freq
out (0x04), a
ld a, 0x0c ; enable hwt2 int
out (0x03), a
ei
im 2
halt
