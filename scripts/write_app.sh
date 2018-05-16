#!/bin/sh

set -u

rom=$1
init_ram=$2
app=$3

out=$(basename -s .8xp $(echo $app | tr '[:upper:]' '[:lower:]'))_mem.bin

h2d() {
    printf "%d" $1
}

PC_START=$(h2d 0x7c000)
RAM_INIT_ADDR=$(h2d 0x87000)
APP_START=$(h2d 0x81d49)

z80asm tests/init/init.s -o init.z
z80asm $init_ram -o iram.z

cp $rom $out                                   # write rom
dd if=/dev/zero of=$out bs=16k seek=32 count=2 # write empty ram

dd if=init.z of=$out bs=1 conv=notrunc seek=$PC_START # write pc start init
dd if=iram.z of=$out bs=1 conv=notrunc seek=$RAM_INIT_ADDR # write ram init
dd if=$app of=$out bs=1 conv=notrunc seek=$APP_START # write app to ram
