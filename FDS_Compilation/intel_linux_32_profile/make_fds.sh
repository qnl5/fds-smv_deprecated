#!/bin/bash
platform=ia32
dir=`pwd`
target=${dir##*/}

source ../SET_MYFDSENV.sh $platform

echo Building $target
make -j4 VPATH="../../FDS_Source" -f ../makefile $target
