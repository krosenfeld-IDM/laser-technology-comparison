#!/bin/bash

SEED=42
RANDOM=$SEED
N_RUN=10

run_model_small () {
    times=()
    for i in $( seq 1 $N_RUN )
    do
        startt=`date +%s%N`
        bash init.sh
        python tlc.py
        endt=`date +%s%N`
        times+=(`expr $endt - $startt`)
    done
    readarray -t sorted < <(printf '%s\n' "${times[@]}" | sort)
    echo -n "numpy-c SIRSingleNode-small (ms): "
    echo "${sorted[(`expr $N_RUN / 2 + $N_RUN % 2`)]} * 0.000001" | bc
}

# save the current working directory so we can revert back to it later
pushd .
# change the current working directory to the one with this file in it
cd "$(dirname "$0")"
run_model_small
# and then revert back to the original working directory
popd