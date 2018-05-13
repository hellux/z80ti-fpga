# split 8xp files that span several 16KB pages
# 8xp files begin at 9d49
# end of page 2 is bffff
# c000 will enter page 3, but it is not placed after page 2 in physical memory
# split like the following
# page2 (RAM 1): 0x0000-0x22b6
# page3 (RAM 0): 0x22b7-0x38c8

set -u # error on no input

suffix=.8xp
xp=$1
name=$(basename -s $suffix $(echo $xp | tr '[:upper:]' '[:lower:]'))

page2_bytes=$(printf "%d" 0x22b7)
dd if=$xp of=${name}_ram1${suffix} bs=1 skip=0 count=$page2_bytes
dd if=$xp of=${name}_ram0${suffix} bs=1 skip=$page2_bytes
