#!/bin/bash

(

echo "Benchmarking julia-ABM"
julia --project=@. SIRSingleNode/julia-ABM/benchmark_sirsinglenode.jl

echo "Benchmarking numpy-numba"
bash SIRSingleNode/numpy-numba/benchmark_sirsinglenode.sh

echo "Benchmarking numpy-c"
bash SIRSingleNode/numpy-c/benchmark_sirsinglenode.sh

echo "Benchmarking sqlLite"
bash SIRSingleNode/sqlLite/benchmark_sirsinglenode.sh

) | tee benchmark_results.txt

julia --project=@. create_benchmark_table.jl