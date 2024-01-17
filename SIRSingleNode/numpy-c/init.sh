#!/bin/bash

pushd .

make

cd "$(dirname "$0")"
python create_pop_as_csv.py 100000
python create_pop_as_csv.py 1000000

popd
