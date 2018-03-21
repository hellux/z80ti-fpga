# Usage: ./aims ENTITY SIMULATION_TIME

set -e

alu_src="tests/z80/alu_tb.vhd src/z80/alu.vhd"

src=$alu_src
entity=$1
simtime=$2

# compile
ghdl -a $src        # analyze designs
ghdl -i $src        # import designs
ghdl -m $entity     # make executable

# simulate
./$entity --wave=wave.ghw  --stop-time=$simtime

# show wave file
#gtkwave wave.ghw

# clean up
rm -f wave.ghw *.o $1
