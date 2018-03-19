# Usage: ./aims ENTITY SIMULATION_TIME

set -e

alu_src="tests/z80/alu_tb.vhd src/z80/alu.vhd"

src=$alu_src
entity=$1
simtime=$2

ghdl -a $src `#analyze designs` \
    && ghdl -i $src `#import designs` \
    && ghdl -m $entity `#make executable` \
    && ./$entity \
        --wave=wave.ghw \
        --stop-time=$simtime `#generate wave file`\
    && gtkwave wave.ghw `#show wave file`

# clean up files
rm -f wave.ghw *.o $1
