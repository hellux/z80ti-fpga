h2d() {
    printf "%d" $1
}

addrloc_log=$(h2d $1)
rom=$2

page_1b=$(h2d 0x6c000)
page_logic=$(h2d 0x4000)

addrloc_phy=$(expr $page_1b - $page_logic + $addrloc_log)
address=$(hexdump -e '1/2 "%04x\n"' -n 2 -s $addrloc_phy $rom)

echo $address at $(printf "%x" $addrloc_phy)
