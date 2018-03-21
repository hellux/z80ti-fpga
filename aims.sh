#!/bin/sh

USAGE="Usage: ./aims [OPTIONS]...

Options:
    -h                      show this help
    -f SRC_FILES_FILE       src files in build/srclists/SRC_FILE_FILE, all 
    -m ENTITY               make executable from src files
                            .vhd files in below tree will be used if -s 
                            not specified
    -s                      run simulation with created executable
    -t TIME                 simulation time
    -a                      stop simulation on assertion error
    -c                      clean up build files and executable
"

# actions
quit=false          # quit immediately
make=false          # make executable
sim=false           # run simulation
clean=false    # remove executable

src=$(find . -name '*.vhd')
entity=
args=

while getopts hm:f:st:awcC OPT; do
    case $OPT in
        h) quit=true ;;
        f) src=$(cat build/srclists/$OPTARG) ;;
        m) entity=$OPTARG; make=true ;;
        s) sim=true ;;
        t) args="$args --stop-time=$OPTARG" ;;
        a) args="$args --assert-level=error" ;;
        c) clean=true ;;
        [?]) quit=true ;;
    esac
done

echo src: $src
echo args: $args
echo entity: $entity

if [ "$quit" = true ]; then
    echo "$USAGE"
    exit 1
fi

if [ "$make" = true ]; then
    ghdl -a $src        # analyze designs
    ghdl -i $src        # import designs
    ghdl -m $entity     # make executable
fi

if [ "$sim" = true ]; then
    ./$entity $args --wave=wave.ghw
fi

if [ "$clean" = true ]; then
    rm -f $entity 
    rm -f wave.ghw
fi

rm -f *.o
