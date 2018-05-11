#!/bin/sh

set -u
rom=$1

write() {
    name=$3
    left=$(printf "%d" $1)
    right=$(printf "%d" $2)
    size=$(expr $right - $left + 1)
    dd if=$rom of=$name.bin bs=1 skip=$left count=$size
}

write 0x02a37 \
      0x02ab2 bc1
write 0x0249f \
      0x024b4 bc2
write 0x6c570 \
      0x6c57f bc3

write 0x05f73 \
      0x05f7d bc_rio0
write 0x060c2 \
      0x060c4 bc_rio1

write 0x5b76 \
      0x5bb0 bc_clrlcdf0
write 0x6358 \
      0x6375 bc_clrlcdf1
write 0x55e5 \
      0x55f3 bc_clrlcdf2
write 0x1813 \
      0x1821 bc_clrlcdf3
write 0x0aae \
      0x0ab6 bc_clrlcdf4
