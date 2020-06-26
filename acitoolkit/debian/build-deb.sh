#!/bin/bash
# Should be run from the root of the source tree
# Set env var REVISION to overwrite the 'revision' field in version string

if [ ! -d debian ]; then
   echo "Directory 'debian' not found"
   exit 1
fi
if [ ! -f debian/changelog.in ]; then
   echo "Debian changelog file not found"
   exit 1
fi
BUILD_DIR=${BUILD_DIR:-`pwd`/debbuild}
mkdir -p $BUILD_DIR
rm -rf $BUILD_DIR/*

# Build python2 package
NAME=`python setup.py --name 2> /dev/null`
VERSION_PY=`python setup.py --version 2> /dev/null`
VERSION=`git describe --tags | tr -d v | cut -d'-' -f1`
REVISION=${REVISION:-1}
python setup.py sdist --dist-dir $BUILD_DIR
SOURCE_FILE=${NAME}-${VERSION_PY}.tar.gz
tar -C $BUILD_DIR -xf $BUILD_DIR/$SOURCE_FILE
SOURCE_DIR=$BUILD_DIR/${NAME}-${VERSION_PY}
cp -H -r debian $SOURCE_DIR/
sed -e "s/@VERSION@/$VERSION/" -e "s/@REVISION@/$REVISION/" ${SOURCE_DIR}/debian/changelog.in > ${SOURCE_DIR}/debian/changelog

mv $BUILD_DIR/$SOURCE_FILE $BUILD_DIR/${NAME}_${VERSION}.orig.tar.gz
pushd ${SOURCE_DIR}
debuild -d -us -uc
popd

# Save the python2 package
cp debbuild/*.deb .
rm -rf debbuild

# Prepare build scripts for python3
cp debian/control .
cp debian/rules .
sed -i "s/python/python3/g" debian/control
sed -i "s/Python2.7/Python3/g" debian/control
sed -i "s/2.7/3.3/g" debian/control
sed -i "s/python2/python3/g" debian/rules

# Build the python3 package
NAME=`python3 setup.py --name 2> /dev/null`
VERSION_PY=`python3 setup.py --version 2> /dev/null`
VERSION=`git describe --tags | tr -d v | cut -d'-' -f1`
REVISION=${REVISION:-1}
python3 setup.py sdist --dist-dir $BUILD_DIR
SOURCE_FILE=${NAME}-${VERSION_PY}.tar.gz
tar -C $BUILD_DIR -xf $BUILD_DIR/$SOURCE_FILE
SOURCE_DIR=$BUILD_DIR/${NAME}-${VERSION_PY}
cp -H -r debian $SOURCE_DIR/
sed -e "s/@VERSION@/$VERSION/" -e "s/@REVISION@/$REVISION/" ${SOURCE_DIR}/debian/changelog.in > ${SOURCE_DIR}/debian/changelog

mv $BUILD_DIR/$SOURCE_FILE $BUILD_DIR/${NAME}_${VERSION}.orig.tar.gz
pushd ${SOURCE_DIR}
debuild -d -us -uc
popd

mv control debian/control
mv rules debian/rules
mv *.deb debbuild/
