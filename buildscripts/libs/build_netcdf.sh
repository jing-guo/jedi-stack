#!/bin/bash
# © Copyright 2020 UCAR
# This software is licensed under the terms of the Apache Licence Version 2.0 which can be obtained at
# http://www.apache.org/licenses/LICENSE-2.0.

set -ex

name="netcdf"
c_version=$1
f_version=$2
cxx_version=$3

# Hyphenated version used for install prefix
compiler=$(echo $JEDI_COMPILER | sed 's/\//-/g')
mpi=$(echo $JEDI_MPI | sed 's/\//-/g')

if $MODULES; then
    set +x
    source $MODULESHOME/init/bash
    module load jedi-$JEDI_COMPILER
    [[ -z $mpi ]] || module load jedi-$JEDI_MPI 
    module try-load szip
    module load hdf5
    [[ -z $mpi ]] || module load pnetcdf
    module list
    set -x

    prefix="${PREFIX:-"/opt/modules"}/$compiler/$mpi/$name/$c_version"
    if [[ -d $prefix ]]; then
        [[ $OVERWRITE =~ [yYtT] ]] && ( echo "WARNING: $prefix EXISTS: OVERWRITING!";$SUDO rm -rf $prefix; $SUDO mkdir $prefix ) \
                                   || ( echo "WARNING: $prefix EXISTS, SKIPPING"; exit 1 )
    fi
else
    prefix=${NETCDF_ROOT:-"/usr/local"}
    [ -f /etc/profile.d/szip-env-vars.sh ] && source /etc/profile.d/szip-env-vars.sh
    [ -f /etc/profile.d/hdf5-env-vars.sh ] && source /etc/profile.d/hdf5-env-vars.sh
    [ -f /etc/profile.d/pnetcdf-env-vars.sh ] && source /etc/profile.d/pnetcdf-env-vars.sh
fi

if [[ ! -z $mpi ]]; then
    export FC=$MPI_FC
    export CC=$MPI_CC
    export CXX=$MPI_CXX
else
    export FC=$SERIAL_FC
    export CC=$SERIAL_CC
    export CXX=$SERIAL_CXX
fi
export F77=$FC
export F9X=$FC

export FFLAGS+=" -fPIC"
export CFLAGS+=" -fPIC"
export CXXFLAGS+=" -fPIC -std=c++11"
export FCFLAGS="$FFLAGS"

gitURLroot="https://github.com/Unidata"

cd ${JEDI_STACK_ROOT}/${PKGDIR:-"pkg"}
curr_dir=$(pwd)

export LDFLAGS+=" -L$HDF5_ROOT/lib -L$SZIP_ROOT/lib"

cd $curr_dir

##################################################
# Download only

if [[ ${DOWNLOAD_ONLY} =~ [yYtT] ]]; then

    version=$c_version
    software=$name-"c"-$version
    [[ -d $software ]] || ( git clone -b "v$version" $gitURLroot/$name-c.git $software )

    version=$f_version
    software=$name-"fortran"-$version
    [[ -d $software ]] || ( git clone -b "v$version" $gitURLroot/$name-fortran.git $software )

    version=$cxx_version
    software=$name-"cxx4"-$version
    [[ -d $software ]] || ( git clone -b "v$version" $gitURLroot/$name-cxx4.git $software )

    exit 0

fi

##################################################

set +x
echo "################################################################################"
echo "BUILDING NETCDF-C"
echo "################################################################################"
set -x

version=$c_version
software=$name-"c"-$version
[[ -d $software ]] || ( git clone -b "v$version" $gitURLroot/$name-c.git $software )
[[ -d $software ]] && cd $software || ( echo "$software does not exist, ABORT!"; exit 1 )
[[ -d build ]] && rm -rf build
mkdir -p build && cd build

[[ -z $mpi ]] || extra_conf="--enable-pnetcdf --enable-parallel-tests"
../configure --prefix=$prefix --enable-netcdf-4 $extra_conf

make V=$MAKE_VERBOSE -j${NTHREADS:-4}
[[ $MAKE_CHECK =~ [yYtT] ]] && make check
$SUDO make install

export CFLAGS+=" -I$prefix/include"
export CXXFLAGS+=" -I$prefix/include"
export LDFLAGS+=" -L$prefix/lib"

# generate modulefile from template
[[ -z $mpi ]] && modpath=compiler || modpath=mpi
$MODULES && update_modules $modpath $name $c_version \
         || echo $software >> ${JEDI_STACK_ROOT}/jedi-stack-contents.log

set +x
echo "################################################################################"
echo "BUILDING NETCDF-Fortran"
echo "################################################################################"

# Load netcdf-c before building netcdf-fortran
if [ "$MODULES" == true ]; then
    module load netcdf
    module list
else
    export NETCDF=$prefix
    export NETCDF_INCLUDES=$prefix/include
    export NETCDF_INCLUDE=$prefix/include
    export NETCDF_LIBRARIES=$prefix/lib
    export NETCDF_CFLAGS="-I$prefix/include"
    export NETCDF_LDFLAGS_C="-L$prefix/lib -lnetcdf"
fi

set -x

cd $curr_dir

version=$f_version
software=$name-"fortran"-$version
[[ -d $software ]] || ( git clone -b "v$version" $gitURLroot/$name-fortran.git $software )
[[ -d $software ]] && cd $software || ( echo "$software does not exist, ABORT!"; exit 1 )
[[ -d build ]] && rm -rf build
mkdir -p build && cd build

../configure --prefix=$prefix --disable-fortran-type-check

#VERBOSE=$MAKE_VERBOSE make -j${NTHREADS:-4}
make V=$MAKE_VERBOSE -j1 #NetCDF-Fortran-4.5.2 & intel/20 have a linker bug if built with j>1
[[ $MAKE_CHECK =~ [yYtT] ]] && make check
$SUDO make install

cd $curr_dir

$MODULES || echo $software >> ${JEDI_STACK_ROOT}/jedi-stack-contents.log

set +x
echo "################################################################################"
echo "BUILDING NETCDF-CXX"
echo "################################################################################"
set -x

version=$cxx_version
software=$name-"cxx4"-$version
[[ -d $software ]] || ( git clone -b "v$version" $gitURLroot/$name-cxx4.git $software )
[[ -d $software ]] && cd $software || ( echo "$software does not exist, ABORT!"; exit 1 )
[[ -d build ]] && rm -rf build
mkdir -p build && cd build

../configure --prefix=$prefix

make V=$MAKE_VERBOSE -j${NTHREADS:-4}
[[ $MAKE_CHECK =~ [yYtT] ]] && make check
$SUDO make install

$MODULES || echo $software >> ${JEDI_STACK_ROOT}/jedi-stack-contents.log

if [ "$MODULES" == false ]; then
    echo "export NETCDF=$prefix" >> /etc/profile.d/$name-env-vars.sh
    echo "export NETCDF_ROOT=$prefix" >> /etc/profile.d/$name-env-vars.sh
    echo "export NETCDF_INCLUDES=$prefix/include" >> /etc/profile.d/$name-env-vars.sh
    echo "export NETCDF_INCLUDE=$prefix/include" >> /etc/profile.d/$name-env-vars.sh
    echo "export NETCDF_LIBRARIES=$prefix/lib" >> /etc/profile.d/$name-env-vars.sh
    echo "export NETCDF_VERSION=$version" >> /etc/profile.d/$name-env-vars.sh
    echo "export NETCDF_FFLAGS=\"-I$prefix/include\"" >> /etc/profile.d/$name-env-vars.sh
    echo "export NETCDF_CFLAGS=\"-I$prefix/include\"" >> /etc/profile.d/$name-env-vars.sh
    echo "export NETCDF_CXXFLAGS=\"-I$prefix/include\"" >> /etc/profile.d/$name-env-vars.sh
    echo "export NETCDF_CXX4FLAGS=\"-I$prefix/include\"" >> /etc/profile.d/$name-env-vars.sh
    echo "export NETCDF_LDFLAGS_F=\"-L$prefix/lib -lnetcdff\"" >> /etc/profile.d/$name-env-vars.sh
    echo "export NETCDF_LDFLAGS_C=\"-L$prefix/lib -lnetcdf\"" >> /etc/profile.d/$name-env-vars.sh
    echo "export NETCDF_LDFLAGS_CXX=\"-L$prefix/lib -lnetcdf -lnetcdf_c++\"" >> /etc/profile.d/$name-env-vars.sh
    echo "export NETCDF_LDFLAGS_CXX4=\"-L$prefix/lib -lnetcdf -lnetcdf_c++4\"" >> /etc/profile.d/$name-env-vars.sh
    echo "export NETCDF_LDFLAGS=\"-L$prefix/lib -lnetcdff\"" >> /etc/profile.d/$name-env-vars.sh
fi
