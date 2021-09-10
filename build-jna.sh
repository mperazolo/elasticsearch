#!/bin/bash

SCRIPT_PATH="$( cd $( dirname ${BASH_SOURCE[0]} ) >/dev/null 2>&1 && pwd )"
SCRIPT_NAME="$( basename ${BASH_SOURCE[0]} )"
source $SCRIPT_PATH/build.env

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

