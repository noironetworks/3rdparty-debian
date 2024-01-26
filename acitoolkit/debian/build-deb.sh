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


# Remove the websocket-client dependency in setup.py, since
# we are already specifying it in the debian/control file,
# and for some reason this name is wrong when JuJu tries
# to resolve the dependencies (works fine with RPMs)
cp setup.py setup.py.orig
sed -i '/websocket-client/d' ./setup.py

# Build python package
function buildPackage {
    PYTHON_BIN=$1
    BUILD_DIR=${BUILD_DIR:-`pwd`/debbuild}
    mkdir -p $BUILD_DIR
    rm -rf $BUILD_DIR/*
    NAME=`${PYTHON_BIN} setup.py --name 2> /dev/null`
    VERSION_PY=`${PYTHON_BIN} setup.py --version 2> /dev/null`
    VERSION=`git describe --tags | tr -d v | cut -d'-' -f1`
    REVISION=${REVISION:-1}
    ${PYTHON_BIN} setup.py sdist --dist-dir $BUILD_DIR
    SOURCE_FILE=${NAME}-${VERSION_PY}.tar.gz
    tar -C $BUILD_DIR -xf $BUILD_DIR/$SOURCE_FILE
    SOURCE_DIR=$BUILD_DIR/${NAME}-${VERSION_PY}
    cp -H -r debian $SOURCE_DIR/
    sed -e "s/@VERSION@/$VERSION/" -e "s/@REVISION@/$REVISION/" ${SOURCE_DIR}/debian/changelog.in > ${SOURCE_DIR}/debian/changelog

    mv $BUILD_DIR/$SOURCE_FILE $BUILD_DIR/${NAME}_${VERSION}.orig.tar.gz
    pushd ${SOURCE_DIR}
    debuild -d -us -uc
    popd
}


# Save the python package
function savePackages {
    cp debbuild/*.deb .
    rm -rf debbuild
}

# Prepare build scripts for python3
function python3Packaging {
    mv setup.py.orig setup.py
    cp debian/control .
    cp debian/rules .
    sed -i "s/python/python3/g" debian/control
    sed -i "s/Python2.7/Python3/g" debian/control
    sed -i "s/2.7/3.3/g" debian/control
    sed -i "s/Package: acitoolkit/Package: python3-acitoolkit/g" debian/control
    sed -i "s/python2/python3/g" debian/rules
}

# restore the original files and debian packages
function restorePackages {
    mv control debian/control
    mv rules debian/rules
    mv *.deb debbuild/
}

buildPackage python2
savePackages
python3Packaging
buildPackage python3
restorePackages
