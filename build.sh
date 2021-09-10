#!/bin/bash

SCRIPT_PATH="$( cd $( dirname ${BASH_SOURCE[0]} ) >/dev/null 2>&1 && pwd )"
SCRIPT_NAME="$( basename ${BASH_SOURCE[0]} )"
source $SCRIPT_PATH/build.env

# spawn build as non root user
if [ `id -u` == 0 ]; then
  ./build-prereqs.sh
  if [ ! $( id -u $USER_NAME 2>/dev/null ) ]; then
    useradd $USER_NAME
  else
    rm -rf /home/$USER_NAME/*
  fi
  LINE="$USER_NAME ALL=(ALL:ALL) NOPASSWD:ALL"
  grep -qF -- "$LINE" /etc/sudoers || echo "$LINE" >> /etc/sudoers
  mkdir -p $EXEC_PATH
  \cp -R $SCRIPT_PATH/* $EXEC_PATH 
  chown -R $USER_NAME.$USER_NAME $EXEC_PATH 
  su -s /bin/bash -c "cd $EXEC_PATH; ./$SCRIPT_NAME" - $USER_NAME
  #pkill -u $USER_NAME
  #userdel -r $USER_NAME
  exit 0
fi

# set output path
if [ ! -d "${OUTPUT_PATH}" ]; then
  OUTPUT_PATH="/tmp/build"
  mkdir -p $OUTPUT_PATH
fi

# extract and patch build files
cd $EXEC_PATH # make sure we're in the right directory

# replace jna library on gradle cache
./build-jna.sh

# main block
cd $EXEC_PATH # make sure we're in the right directory
./gradlew :distribution:packages:oss-no-jdk-rpm:assemble
#./gradlew -Dbuild.snapshot=false :distribution:packages:oss-no-jdk-rpm:assemble

# save build artifacts
./build-save.sh

