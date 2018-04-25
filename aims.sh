#!/bin/sh

USAGE="Usage: ./aims [OPTIONS]...

Options:
    -h                      show this help
    -A                      analyze src files
    -M ENTITY               analyze, make executable for ENTITY
    -S ENTITY               analyze, make, simulate ENTITY and generate wave
    -C                      clean up build files and executable
    -u SRC_LIST             unit, name of file with list of src files in
                            build/srclists, all .vhd files in below tree will
                            be used if -f not specified
    -z Z80 ASM FILE         compile and run z80 asm file
    -a                      abort simulation on assertion error
    -t TIME                 simulation time
    -w FILENAME             name of generated wave file -- default: wave.ghw

Examples:
    simulate alu_tb when all alu src files listed in build/srclists/alu
        ./aims -u alu -S alu_tb
    analyze all alu src files
        ./aims -u alu -A
    analyze all files in src/z80
        ./aims -f \"src/z80/*.vhd\" -A
"

# actions
quit=false          # quit immediately
analyze=false       # analyze src files
make=false          # make executable
sim=false           # run simulation
clean=false         # remove executable
asm=false;          # assemble z80 obj

src=$(find . -name '*.vhd')
asm_src=""
entity=""
args="--ieee-asserts=disable"
wave="wave.ghw"
args_ghdl="--workdir=build --ieee=synopsys"

while getopts hAM:S:Cf:z:u:at:w: OPT; do
    case $OPT in
        h) quit=true ;;
        A) analyze=true ;;
        M) analyze=true; make=true;          entity=$OPTARG ;;
        S) analyze=true; make=true; sim=true entity=$OPTARG ;;
        C) clean=true ;;
        f) src=$OPTARG ;;
        z) asm=true; asm_src=$OPTARG ;;
        u) 
            src=$(cat build/srclists/$OPTARG);
            if [ -z "$src" ]; then
                echo "unit '$OPTARG' not found in build/srclists/"
                exit 1
            fi ;;
        a) args="$args --assert-level=error" ;;
        t) args="$args --stop-time=$OPTARG" ;;
        w) wave=$OPTARG ;;
        [?]) quit=true ;;
    esac
done

if [ "$quit" = true ]; then
    echo "$USAGE"
    exit 1
fi

if [ "$asm" = true ]; then
    z80asm $asm_src --list
    if [ $? != '0' ]; then
        exit 1
    fi
fi

if [ "$analyze" = true ]; then
    ghdl -a $args_ghdl $src # analyze designs
    if [ "$make" = true -a $? = '0' ]; then
        ghdl -i $args_ghdl $src    # import designs
        ghdl -m $args_ghdl $entity # make executable

        if [ "$sim" = true -a $? = '0' ]; then
            ./$entity $args --wave=$wave
        fi
    fi
fi

if [ "$clean" = true ]; then
    rm -f $entity 
fi

rm -f *.o *.cf
ghdl --clean --workdir=build
