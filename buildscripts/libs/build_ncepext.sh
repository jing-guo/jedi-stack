#!/bin/bash
# © Copyright 2020 UCAR
# This software is licensed under the terms of the Apache Licence Version 2.0 which can be obtained at
# http://www.apache.org/licenses/LICENSE-2.0.
#
# Note - the compilers and install paths for this are currently hardwired in,
# including some in /usr/local.  This might work for the container but it
# needs more work to fully integrate into the build system

set -ex

name="ncepext"
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
    prefix=${NCEPEXT:-"/usr/local"}
    [ -f /etc/profile.d/jpeg-env-vars.sh ] && source /etc/profile.d/jpeg-env-vars.sh
    [ -f /etc/profile.d/png-env-vars.sh ] && source /etc/profile.d/png-env-vars.sh
    [ -f /etc/profile.d/netcdf-env-vars.sh ] && source /etc/profile.d/netcdf-env-vars.sh
    [ -f /etc/profile.d/esmf-env-vars.sh ] && source /etc/profile.d/esmf-env-vars.sh

fi

cd ${JEDI_STACK_ROOT}/${PKGDIR:-"pkg"}

gitURL="https://github.com/NOAA-EMC/NCEPLIBS-external.git"
version=$version
software=$name-$version
[[ -d $software ]] || ( git clone -b "$version" $gitURL $software )
[[ -d $software ]] && cd $software || ( echo "$software does not exist, ABORT!"; exit 1 )
git submodule update --init --recursive
[[ -d build ]] && rm -rf build
mkdir -p build && cd build

cmake -DCMAKE_INSTALL_PREFIX=$prefix -DBUILD_MPI=OFF -DBUILD_NETCDF=OFF -DBUILD_PNG=OFF -DBUILD_ESMF=OFF ..

make V=$MAKE_VERBOSE -j${NTHREADS:-4}

# generate modulefile from template
$MODULES && update_modules compiler $name $version \
         || echo $name $version >> ${JEDI_STACK_ROOT}/jedi-stack-contents.log
