#!/bin/bash
# © Copyright 2020 UCAR
# This software is licensed under the terms of the Apache Licence Version 2.0 which can be obtained at
# http://www.apache.org/licenses/LICENSE-2.0.

set -ex

name="eckit"
# source should be either ecmwf or jcsda (fork)
source=$1
version=$2

# Hyphenated version used for install prefix
compiler=$(echo $JEDI_COMPILER | sed 's/\//-/g')
mpi=$(echo $JEDI_MPI | sed 's/\//-/g')

if $MODULES; then
    set +x
    source $MODULESHOME/init/bash
    module load jedi-$JEDI_COMPILER
    module load jedi-$JEDI_MPI
    module try-load cmake
    module try-load ecbuild
    module try-load zlib
    module try-load boost-headers
    module try-load eigen
    module list
    set -x

    prefix="${PREFIX:-"/opt/modules"}/$compiler/$mpi/$name/$source-$version"
    if [[ -d $prefix ]]; then
        [[ $OVERWRITE =~ [yYtT] ]] && ( echo "WARNING: $prefix EXISTS: OVERWRITING!";$SUDO rm -rf $prefix ) \
                                   || ( echo "WARNING: $prefix EXISTS, SKIPPING"; exit 1 )
    fi
else
    prefix=${ECKIT_ROOT:-"/usr/local"}
    [ -f /etc/profile.d/ecbuild-env-vars.sh ] && source /etc/profile.d/ecbuild-env-vars.sh
    [ -f /etc/profile.d/zlib-env-vars.sh ] && source /etc/profile.d/zlib-env-vars.sh
    [ -f /etc/profile.d/boost-headers-env-vars.sh ] && source /etc/profile.d/boost-headers-env-vars.sh
    [ -f /etc/profile.d/eigen-env-vars.sh ] && source /etc/profile.d/eigen-env-vars.sh
fi

export FC=$MPI_FC
export CC=$MPI_CC
export CXX=$MPI_CXX
export F9X=$FC
export CXXFLAGS+=" -fPIC"

software=$name
cd ${JEDI_STACK_ROOT}/${PKGDIR:-"pkg"}
[[ -d $software ]] || git clone https://github.com/$source/$software.git
[[ ${DOWNLOAD_ONLY} =~ [yYtT] ]] && exit 0
[[ -d $software ]] && cd $software || ( echo "$software does not exist, ABORT!"; exit 1 )
git fetch --tags
git checkout $version
sed -i -e 's/project( eckit CXX/project( eckit CXX Fortran/' CMakeLists.txt
[[ -d build ]] && $SUDO rm -rf build
mkdir -p build && cd build

ecbuild -DCMAKE_INSTALL_PREFIX=$prefix --build=Release ..
VERBOSE=$MAKE_VERBOSE make -j${NTHREADS:-4}
VERBOSE=$MAKE_VERBOSE $SUDO make install

# generate modulefile from template
$MODULES && update_modules mpi $name $source-$version \
         || echo $name $source-$version >> ${JEDI_STACK_ROOT}/jedi-stack-contents.log

if [ "$MODULES" == false ]; then
    echo "export eckit_ROOT=$prefix" >> /etc/profile.d/$name-env-vars.sh
    echo "export eckit_DIR=$prefix/lib/cmake/eckit" >> /etc/profile.d/$name-env-vars.sh
    echo "export ECKIT_PATH=$prefix" >> /etc/profile.d/$name-env-vars.sh
    echo "export ECKIT_VERSION=$version" >> /etc/profile.d/$name-env-vars.sh
fi