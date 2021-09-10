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
cd elasticsearch

# trigger download of custom jna library to cache
./gradlew :distribution:archives:oss-no-jdk-linux-tar:assemble
rm -rf distribution/archives/oss-no-jdk-linux-tar/build

# download jna
echo "Cloning jna-${JNAVERS}"
cd ${EXEC_PATH} # make sure we're in the right directory
git clone https://github.com/java-native-access/jna.git
cd jna
git checkout ${JNAVERS}

# fix cached jna library
JAR_FIND=$( find ${CACHE_DIR} -name ${JAR_NAME} | grep "org.elasticsearch" )
JAR_PATH=$( dirname ${JAR_FIND} )
cd ${JAR_PATH}
mkdir tmp
cd tmp
echo "Extract contents from ${JAR_NAME}"
jar xvf ../${JAR_NAME}
mv ../${JAR_NAME} ../${JAR_NAME}.old
cd com/sun/jna
mkdir linux-ppc64le
cd linux-ppc64le
echo "Adding native support for ppc64le"
jar xvf ${EXEC_PATH}/jna/dist/linux-ppc64le.jar
rm -rf META-INF/
cd ${JAR_PATH}/tmp
echo "Repacking ${JAR_NAME}"
jar cvf ../${JAR_NAME} .
cd ..
rm -rf tmp

# main block
cd $EXEC_PATH # make sure we're in the right directory
cd elasticsearch
./gradlew :distribution:packages:oss-no-jdk-rpm:assemble
#./gradlew -Dbuild.snapshot=false :distribution:packages:oss-no-jdk-rpm:assemble

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

