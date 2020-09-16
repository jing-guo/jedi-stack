#!/bin/bash
# © Copyright 2020 UCAR
# This software is licensed under the terms of the Apache Licence Version 2.0 which can be obtained at
# http://www.apache.org/licenses/LICENSE-2.0.

set -ex

name="xerces"
version=$1

# Hyphenated version used for install prefix
compiler=$(echo $JEDI_COMPILER | sed 's/\//-/g')

# manage package dependencies here
if $MODULES; then
    set +x
    source $MODULESHOME/init/bash
    module load jedi-$JEDI_COMPILER
    module list
    set -x

    prefix="${PREFIX:-"/opt/modules"}/$compiler/$name/$version"
    if [[ -d $prefix ]]; then
        [[ $OVERWRITE =~ [yYtT] ]] && ( echo "WARNING: $prefix EXISTS: OVERWRITING!";$SUDO rm -rf $prefix ) \
                                   || ( echo "WARNING: $prefix EXISTS, SKIPPING"; exit 1 )
    fi
else
    prefix=${XERCES_ROOT:-"/usr/local"}
fi

export FC=$SERIAL_FC
export CC=$SERIAL_CC
export CXX=$SERIAL_CXX

export FFLAGS+=" -fPIC"
export CFLAGS+=" -fPIC"
export CXXFLAGS+=" -fPIC"
export FCFLAGS="$FFLAGS"

cd ${JEDI_STACK_ROOT}/${PKGDIR:-"pkg"}

software=$name-c-$version
vnum=$(echo $version | cut -d. -f1)
url=https://archive.apache.org/dist/xerces/c/$vnum/sources/$software.tar.gz
[[ -d $software ]] || ( $WGET $url; tar -xf $software.tar.gz )
[[ ${DOWNLOAD_ONLY} =~ [yYtT] ]] && exit 0
[[ -d $software ]] && cd $software || ( echo "$software does not exist, ABORT!"; exit 1 )
[[ -d build ]] && rm -rf build
mkdir -p build && cd build

../configure --prefix=$prefix --with-curl --without-icu

make -j${NTHREADS:-4} 
[[ $MAKE_CHECK =~ [yYtT] ]] && make check
$SUDO make install

# generate modulefile from template
$MODULES && update_modules compiler $name $version \
         || echo $name $version >> ${JEDI_STACK_ROOT}/jedi-stack-contents.log

if [ "$MODULES" == false ]; then
    echo "export XERCES_ROOT=$prefix" >> /etc/profile.d/$name-env-vars.sh
    echo "export XERCES_INCLUDES=$prefix/include" >> /etc/profile.d/$name-env-vars.sh
    echo "export XERCES_LIBRARIES=$prefix/lib" >> /etc/profile.d/$name-env-vars.sh
    echo "export XERCES_VERSION=$version" >> /etc/profile.d/$name-env-vars.sh
fi