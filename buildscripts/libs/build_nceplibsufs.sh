#!/bin/bash
# © Copyright 2020 UCAR
# This software is licensed under the terms of the Apache Licence Version 2.0 which can be obtained at
# http://www.apache.org/licenses/LICENSE-2.0.
#
# Note - the compilers and install paths for this are currently hardwired in,
# including some in /usr/local.  This might work for the container but it
# needs more work to fully integrate into the build system


function get_version {
    set -ex

    echo $# arguments 
    if [$# -ne 3]; 
        then echo "illegal number of parameters"
        return 1
    fi
    name=$1
    $2=""
    $3=""

    echo $(find . -maxdepth 1 -name "$name-*" -type d | wc -l)
    if [[ $(find . -maxdepth 1 -name "$name-*" -type d | wc -l) -eq 1 ]]; then
        libdir=$(find . -maxdepth 1 -name "$name-*" -type d | sed 's!.*/!!')
        echo $libdir
        eval "$2=${libdir}"
        eval "$3=$(echo $libdir | cut -d'-' -f 2)"
    else
        echo "Either too few or too many directories matching pattern: $name-"
        return 1
    fi
}


set -ex

ncepext_name="NCEPEXT"
nceplibs_name="NCEPLIBS"
ncepext_version=$1
nceplibs_version=$2

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
    [ -f /etc/profile.d/szip-env-vars.sh ] && source /etc/profile.d/szip-env-vars.sh
    [ -f /etc/profile.d/zlib-env-vars.sh ] && source /etc/profile.d/zlib-env-vars.sh
    [ -f /etc/profile.d/hdf5-env-vars.sh ] && source /etc/profile.d/hdf5-env-vars.sh
    [ -f /etc/profile.d/jpeg-env-vars.sh ] && source /etc/profile.d/jpeg-env-vars.sh
    [ -f /etc/profile.d/png-env-vars.sh ] && source /etc/profile.d/png-env-vars.sh
    [ -f /etc/profile.d/netcdf-env-vars.sh ] && source /etc/profile.d/netcdf-env-vars.sh
    [ -f /etc/profile.d/esmf-env-vars.sh ] && source /etc/profile.d/esmf-env-vars.sh

fi

pkgdir=${JEDI_STACK_ROOT}/${PKGDIR:-"pkg"}
cd $pkgdir

##################################################

set +x
echo "################################################################################"
echo "BUILDING NCEPLIBS-external"
echo "################################################################################"
set -x

[[ -f $prefix/wgrib2-* ]] && rm -rf $prefix/wgrib2-*

gitURL="https://github.com/NOAA-EMC/NCEPLIBS-external.git"
software=$ncepext_name-$ncepext_version
[[ -d $software ]] || ( git clone $gitURL $software )
[[ -d $software ]] && cd $software || ( echo "$software does not exist, ABORT!"; exit 1 )
git checkout tags/$ncepext_version
git submodule update --init --recursive
[[ -d build ]] && rm -rf build
mkdir -p build && cd build

cmake -DCMAKE_INSTALL_PREFIX=$prefix -DBUILD_MPI=OFF -DBUILD_NETCDF=OFF -DBUILD_PNG=OFF -DBUILD_ESMF=OFF ..

make V=$MAKE_VERBOSE -j${NTHREADS:-4}

##################################################

set +x
echo "################################################################################"
echo "BUILDING NCEPLIBS"
echo "################################################################################"
set -x

cd $pkgdir

[[ -f $prefix/bacio-* ]] && rm -rf $prefix/bacio-*
[[ -f $prefix/bufr-* ]] && rm -rf $prefix/bufr-*
[[ -f $prefix/crtm-* ]] && rm -rf $prefix/crtm-*
[[ -f $prefix/g2-* ]] && rm -rf $prefix/g2-*
[[ -f $prefix/g2tmpl-* ]] && rm -rf $prefix/g2tmpl-*
[[ -f $prefix/gfsio-* ]] && rm -rf $prefix/gfsio-*
[[ -f $prefix/ip-* ]] && rm -rf $prefix/ip-*
[[ -f $prefix/landsfcutil-* ]] && rm -rf $prefix/landsfcutil-*
[[ -f $prefix/nceppost-* ]] && rm -rf $prefix/nceppost-*
[[ -f $prefix/nemsio-* ]] && rm -rf $prefix/nemsio-*
[[ -f $prefix/nemsiogfs-* ]] && rm -rf $prefix/nemsiogfs-*
[[ -f $prefix/sfcio-* ]] && rm -rf $prefix/sfcio-*
[[ -f $prefix/sigio-* ]] && rm -rf $prefix/sigio-*
[[ -f $prefix/sp-* ]] && rm -rf $prefix/sp-*
[[ -f $prefix/w3emc-* ]] && rm -rf $prefix/w3emc-*
[[ -f $prefix/w3nco-* ]] && rm -rf $prefix/w3nco-*
[[ -f $prefix/wrf_io-* ]] && rm -rf $prefix/wrf_io-*

gitURL="https://github.com/NOAA-EMC/NCEPLIBS.git"
software=$nceplibs_name
[[ -d $software ]] || ( git clone $gitURL $software )
[[ -d $software ]] && cd $software || ( echo "$software does not exist, ABORT!"; exit 1 )
[[ -d build ]] && rm -rf build
mkdir -p build && cd build

cmake -DCMAKE_INSTALL_PREFIX=/usr/local ..

make V=$MAKE_VERBOSE -j${NTHREADS:-4}

# generate modulefile from template
$MODULES && make deploy \
         || echo $name $version >> ${JEDI_STACK_ROOT}/jedi-stack-contents.log

if [ "$MODULES" == false ]; then
    [[ -f /etc/profile.d/wgrib2-env-vars.sh ]] && rm -rf /etc/profile.d/wgrib2-env-vars.sh
    echo "export NCEPEXT_ROOT=$prefix" > /etc/profile.d/$ncepext_name-env-vars.sh

    cd $prefix
    get_version bacio libdir version
    if [[ "${libdir}" -ne "" && "${version}" -ne "" ]]; then
        [[ -f /etc/profile.d/bacio-env-vars.sh ]] && rm -rf /etc/profile.d/bacio-env-vars.sh
        echo "export bacio_VER=$version" >> /etc/profile.d/bacio-env-vars.sh
        echo "export bacio_SRC=$pkgdir/$software/" >> /etc/profile.d/bacio-env-vars.sh
        echo "export bacio_LIB4=$prefix/$libdir/lib${libdir}_4.a" >> /etc/profile.d/bacio-env-vars.sh
        echo "export bacio_LIB8=$prefix/$libdir/lib${libdir}_8.a" >> /etc/profile.d/bacio-env-vars.sh
    fi

    get_version bufr libdir version
    if [[ "${libdir}" -ne "" && "${version}" -ne "" ]]; then
        [[ -f /etc/profile.d/bacio-env-vars.sh ]] && rm -rf /etc/profile.d/bacio-env-vars.sh
        echo "export bufr_VER=$version" >> /etc/profile.d/bacio-env-vars.sh
        echo "export bacio_SRC=$pkgdir/$software/" >> /etc/profile.d/bacio-env-vars.sh
        echo "export bacio_LIB4=$prefix/$libdir/lib${libdir}_4.a" >> /etc/profile.d/bacio-env-vars.sh
        echo "export bacio_LIB8=$prefix/$libdir/lib${libdir}_8.a" >> /etc/profile.d/bacio-env-vars.sh

        setenv ${bname}_VER  v$ver
setenv ${bname}_SRC  $dsrc/${lname}_v${ver}
setenv ${bname}_LIB4 $dlib/lib${lname}_v${ver}_4_64.a
setenv ${bname}_LIB8 $dlib/lib${lname}_v${ver}_8_64.a
setenv ${bname}_LIBd $dlib/lib${lname}_v${ver}_d_64.a
setenv ${bname}_LIBs $dlib/lib${lname}_v${ver}_s_64.a
setenv ${bname}_LIB4_DA $dlib/lib${lname}_v${ver}_4_64_DA.a
setenv ${bname}_LIB8_DA $dlib/lib${lname}_v${ver}_8_64_DA.a
setenv ${bname}_LIBd_DA $dlib/lib${lname}_v${ver}_d_64_DA.a
    fi  bv        
    echo "export NCEPLIBS_ROOT=$prefix" >> /etc/profile.d/$nceplibs_name-env-vars.sh

    


fi
