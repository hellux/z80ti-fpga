rom=$1

bc1_l=$(printf "%d" 0x02a37)
bc1_r=$(printf "%d" 0x02ab2)
bc1_s=$(expr $bc1_r - $bc1_l + 1)

bc2_l=$(printf "%d" 0x0249f)
bc2_r=$(printf "%d" 0x024b4)
bc2_s=$(expr $bc2_r - $bc2_l + 1)

bc3_l=$(printf "%d" 0x6c570)
bc3_r=$(printf "%d" 0x6c57f)
bc3_s=$(expr $bc3_r - $bc3_l + 1)

dd if=$rom of=bc1.bin bs=1 skip=$bc1_l count=$bc1_s
dd if=$rom of=bc2.bin bs=1 skip=$bc2_l count=$bc2_s
dd if=$rom of=bc3.bin bs=1 skip=$bc3_l count=$bc3_s
