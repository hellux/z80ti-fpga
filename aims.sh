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

src=$(find . -name '*.vhd')
entity=""
args=""
wave="wave.ghw"

while getopts hAM:S:Cf:e:at:w: OPT; do
    case $OPT in
        h) quit=true ;;
        A) analyze=true ;;
        M) analyze=true; make=true;          entity=$OPTARG ;;
        S) analyze=true; make=true; sim=true entity=$OPTARG ;;
        C) clean=true ;;
        f) src=$OPTARG ;;
        u) src=$(cat build/srclists/$OPTARG) ;;
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

if [ "$analyze" = true ]; then
    ghdl -a $src        # analyze designs
    if [ "$make" = true -a $? = '0' ]; then
        ghdl -i $src    # import designs
        ghdl -m $entity # make executable

        if [ "$sim" = true ]; then
            ./$entity $args --wave=$wave
        fi
    fi
fi

if [ "$clean" = true ]; then
    rm -f $entity 
fi

rm -f *.o *.cf
