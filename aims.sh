#!/bin/sh

USAGE="Usage: ./aims [OPTIONS]...

Options:
    -h                      show this help
    -A                      analyze src files
    -M ENTITY               analyze, make ENTITY
    -S ENTITY               analyze, make, simulate ENTITY
    -C                      clean up build files and executable
    -f SRC_FILES_FILE       src files in build/srclists/SRC_FILE_FILE, all 
                            .vhd files in below tree will be used if -s 
                            not specified
    -a                      abort simulation on assertion error
    -t TIME                 simulation time
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

while getopts hAM:S:Cf:at: OPT; do
    case $OPT in
        h) quit=true ;;
        A) analyze=true ;;
        M) analyze=true; make=true;          entity=$OPTARG ;;
        S) analyze=true; make=true; sim=true entity=$OPTARG ;;
        C) clean=true ;;
        f) src=$(cat build/srclists/$OPTARG) ;;
        a) args="$args --assert-level=error" ;;
        t) args="$args --stop-time=$OPTARG" ;;
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
            ./$entity $args --wave=wave.ghw
        fi
    fi
fi

if [ "$clean" = true ]; then
    rm -f $entity 
fi

rm -f *.o *.cf
