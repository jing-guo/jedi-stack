#!/bin/bash
# © Copyright 2020 UCAR
# This software is licensed under the terms of the Apache Licence Version 2.0 which can be obtained at
# http://www.apache.org/licenses/LICENSE-2.0.

set -ex

name="lapack"
version=$1

# Hyphenated version used for install prefix
compiler=$(echo $JEDI_COMPILER | sed 's/\//-/g')

# manage package dependencies here
if $MODULES; then
    set +x
    source $MODULESHOME/init/bash
    module load jedi-$JEDI_COMPILER
    module try-load cmake
    module list
    set -x

    prefix="${PREFIX:-"/opt/modules"}/$compiler/$name/$version"
    if [[ -d $prefix ]]; then
        [[ $OVERWRITE =~ [yYtT] ]] && ( echo "WARNING: $prefix EXISTS: OVERWRITING!";$SUDO rm -rf $prefix ) \
                                   || ( echo "WARNING: $prefix EXISTS, SKIPPING"; exit 1 )
    fi

else
    prefix=${LAPACK_ROOT:-"/usr/local"}
fi

export FC=$SERIAL_FC
export CC=$SERIAL_CC

export FFLAGS="-fPIC ${FFLAGS}"
export CFLAGS="-fPIC ${CFLAGS}"

cd ${JEDI_STACK_ROOT}/${PKGDIR:-"pkg"}

software=$name-$version
tarball=v$version.tar.gz
url="https://github.com/Reference-LAPACK/lapack/archive/$tarball"
[[ -d $software ]] || ( $WGET $url; tar -xf $tarball )
[[ ${DOWNLOAD_ONLY} =~ [yYtT] ]] && exit 0
[[ -d $software ]] && cd $software || ( echo "$software does not exist, ABORT!"; exit 1 )
[[ -d build ]] && rm -rf build

# Add CMAKE_INSTALL_LIBDIR to make sure it will be installed under lib not lib64
cmake -H. -Bbuild -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_Fortran_COMPILER=$SERIAL_FC
cd build
VERBOSE=$MAKE_VERBOSE make -j${NTHREADS:-4}
[[ $MAKE_CHECK =~ [yYtT] ]] && make check
VERBOSE=$MAKE_VERBOSE $SUDO make install

# generate modulefile from template
$MODULES && update_modules compiler $name $version \
         || echo $name $version >> ${JEDI_STACK_ROOT}/jedi-stack-contents.log

if [ "$MODULES" == false ]; then
    echo "export LAPACK_ROOT=$prefix" >> /etc/profile.d/$name-env-vars.sh
    echo "export LAPACK_DIR=$prefix" >> /etc/profile.d/$name-env-vars.sh
    echo "export LAPACK_PATH=$prefix" >> /etc/profile.d/$name-env-vars.sh
    echo "export LAPACK_INCLUDES=$prefix/include" >> /etc/profile.d/$name-env-vars.sh
    echo "export LAPACK_LIBRARIES=$prefix/lib" >> /etc/profile.d/$name-env-vars.sh
    echo "export LAPACK_LIBDIR=$prefix/lib" >> /etc/profile.d/$name-env-vars.sh
    echo "export LAPACK_VERSION=$version" >> /etc/profile.d/$name-env-vars.sh
fi