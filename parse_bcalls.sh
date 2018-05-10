rom=$1

bc1_l=$(printf "%d" 0x2a37)
bc1_r=$(printf "%d" 0x2ab2)
bc1_s=$(expr $bc1_r - $bc1_l + 1)

bc2_l=$(printf "%d" 0x249f)
bc2_r=$(printf "%d" 0x24b4)
bc2_s=$(expr $bc2_r - $bc2_l + 1)

dd if=$rom of=bc1.bin bs=1 skip=$bc1_l count=$bc1_s
dd if=$rom of=bc2.bin bs=1 skip=$bc2_l count=$bc2_s
