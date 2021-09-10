#!/bin/bash

SCRIPT_PATH="$( cd $( dirname ${BASH_SOURCE[0]} ) >/dev/null 2>&1 && pwd )"
SCRIPT_NAME="$( basename ${BASH_SOURCE[0]} )"
source $SCRIPT_PATH/build.env

# save build artifacts
IFS=","
for i in "${ARTIFACTS[@]}"
do
  set -- $i
  if [ -f "$1" ]; then
    echo Copying $1 to $OUTPUT_PATH/$2/$3
    sudo mkdir -p $OUTPUT_PATH/$2
    sudo \cp $1 $OUTPUT_PATH/$2/$3
  fi
done

