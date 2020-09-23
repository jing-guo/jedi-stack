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

    name=$1

    echo name=$name
    echo $(find . -maxdepth 1 -name "$name-*" -type d | wc -l)
    if [[ $(find . -maxdepth 1 -name "$name-*" -type d | wc -l) -eq 1 ]]; then
        libdirectory=$(find . -maxdepth 1 -name "$name-*" -type d | sed 's!.*/!!')
        echo $libdirectory
        eval "$2=${libdirectory}"
        eval "$3='$(echo $libdirectory | cut -d'-' -f 2)'"
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
[[ -d $software ]] || ( git clone -b $ncepext_version $gitURL $software )
[[ -d $software ]] && cd $software || ( echo "$software does not exist, ABORT!"; exit 1 )
git submodule update --init --recursive
export LIBPNG_ROOT=$prefix
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
software=$nceplibs_name-$nceplibs_version
[[ -d $software ]] || ( git clone -b $nceplibs_version $gitURL $software )
[[ -d $software ]] && cd $software || ( echo "$software does not exist, ABORT!"; exit 1 )
[[ -d build ]] && rm -rf build
mkdir -p build && cd build

cmake -DCMAKE_INSTALL_PREFIX=/usr/local ..

make V=$MAKE_VERBOSE -j${NTHREADS:-4}

# generate modulefile from template
$MODULES && make deploy \
         || echo $name $version >> ${JEDI_STACK_ROOT}/jedi-stack-contents.log

if [ "$MODULES" == false ]; then
    libdir=""
    version=""
    cd $prefix
    libname=bacio
    get_version $libname libdir version
    if [[ "$libdir" != "" && "$version" != "" ]]; then
        [[ -f /etc/profile.d/$libname-env-vars.sh ]] && rm -rf /etc/profile.d/$libname-env-vars.sh
        echo "export bacio_VER=$version" >> /etc/profile.d/$libname-env-vars.sh
        echo "export bacio_SRC=$pkgdir/$software" >> /etc/profile.d/$libname-env-vars.sh
        echo "export bacio_LIB4=$prefix/$libdir/lib${libname}_4.a" >> /etc/profile.d/$libname-env-vars.sh
        echo "export bacio_LIB8=$prefix/$libdir/lib${libname}_8.a" >> /etc/profile.d/$libname-env-vars.sh
        echo "export BACIO_VER=$version" >> /etc/profile.d/$libname-env-vars.sh
        echo "export BACIO_SRC=$pkgdir/$software" >> /etc/profile.d/$libname-env-vars.sh
        echo "export BACIO_LIB4=$prefix/$libdir/lib/lib${libname}_4.a" >> /etc/profile.d/$libname-env-vars.sh
        echo "export BACIO_LIB8=$prefix/$libdir/lib/lib${libname}_8.a" >> /etc/profile.d/$libname-env-vars.sh
    fi

    libname="bufr"
    get_version $libname libdir version
    if [[ "$libdir" != "" && "$version" != "" ]]; then
        [[ -f /etc/profile.d/$libname-env-vars.sh ]] && rm -rf /etc/profile.d/$libname-env-vars.sh
        echo "export bufr_VER=$version" >> /etc/profile.d/$libname-env-vars.sh
        echo "export bufr_SRC=$pkgdir/$software" >> /etc/profile.d/$libname-env-vars.sh
        echo "export bufr_LIB4=$prefix/$libdir/lib/lib${libname}_4_64.a" >> /etc/profile.d/$libname-env-vars.sh
        echo "export bufr_LIB8=$prefix/$libdir/lib/lib${libname}_8_64.a" >> /etc/profile.d/$libname-env-vars.sh
        echo "export bufr_LIBd=$prefix/$libdir/lib/lib${libname}_d_64.a" >> /etc/profile.d/$libname-env-vars.sh
        echo "export bufr_LIBs=$prefix/$libdir/lib/lib${libname}_s_64.a" >> /etc/profile.d/$libname-env-vars.sh
        echo "export bufr_LIB4_DA=$prefix/$libdir/lib/lib${libname}_4_64_DA.a" >> /etc/profile.d/$libname-env-vars.sh
        echo "export bufr_LIB8_DA=$prefix/$libdir/lib/lib${libname}_8_64_DA.a" >> /etc/profile.d/$libname-env-vars.sh
        echo "export bufr_LIBd_DA=$prefix/$libdir/lib/lib${libname}_d_64_DA.a" >> /etc/profile.d/$libname-env-vars.sh
    fi

    libname="crtm"
    get_version $libname libdir version
    if [[ "$libdir" != "" && "$version" != "" ]]; then
        [[ -f /etc/profile.d/$libname-env-vars.sh ]] && rm -rf /etc/profile.d/$libname-env-vars.sh
        echo "export CRTM_VER=$version" >> /etc/profile.d/$libname-env-vars.sh
        echo "export CRTM_SRC=$pkgdir/$software" >> /etc/profile.d/$libname-env-vars.sh
        echo "export CRTM_INC=$prefix/$libdir/include" >> /etc/profile.d/$libname-env-vars.sh
        echo "export CRTM_LIB=$prefix/$libdir/lib/lib${libname}.a" >> /etc/profile.d/$libname-env-vars.sh
        # I'm sure this doesn't work as the fix files need to be built in separate process
        echo "export CRTM_FIX=$pkgdir/$software" >> /etc/profile.d/$libname-env-vars.sh
    fi

    libname=g2
    get_version $libname libdir version
    if [[ "$libdir" != "" && "$version" != "" ]]; then
        [[ -f /etc/profile.d/$libname-env-vars.sh ]] && rm -rf /etc/profile.d/$libname-env-vars.sh
        echo "export G2_VER=$version" >> /etc/profile.d/$libname-env-vars.sh
        echo "export G2_SRC=$pkgdir/$software" >> /etc/profile.d/$libname-env-vars.sh
        echo "export G2_LIB4=$prefix/$libdir/lib/lib${libname}_4.a" >> /etc/profile.d/$libname-env-vars.sh
        echo "export G2_LIBd=$prefix/$libdir/lib/lib${libname}_d.a" >> /etc/profile.d/$libname-env-vars.sh
        echo "export G2_INC4=$prefix/$libdir/include_4" >> /etc/profile.d/$libname-env-vars.sh
        echo "export G2_INCd=$prefix/$libdir/include_d" >> /etc/profile.d/$libname-env-vars.sh
    fi

    libname=g2tmpl
    get_version $libname libdir version
    if [[ "$libdir" != "" && "$version" != "" ]]; then
        [[ -f /etc/profile.d/$libname-env-vars.sh ]] && rm -rf /etc/profile.d/$libname-env-vars.sh
        echo "export G2TMPL_VER=$version" >> /etc/profile.d/$libname-env-vars.sh
        echo "export G2TMPL_SRC=$pkgdir/$software" >> /etc/profile.d/$libname-env-vars.sh
        echo "export G2TMPL_INC=$prefix/$libdir/include" >> /etc/profile.d/$libname-env-vars.sh
        echo "export G2TMPL_LIB=$prefix/$libdir/lib/lib${libname}.a" >> /etc/profile.d/$libname-env-vars.sh
    fi

    libname=gfsio
    get_version $libname libdir version
    echo for $libname, libdir=$libdir, version=$version
    if [[ "$libdir" != "" && "$version" != "" ]]; then
        [[ -f /etc/profile.d/$libname-env-vars.sh ]] && rm -rf /etc/profile.d/$libname-env-vars.sh
        echo "export GFSIO_VER=$version" >> /etc/profile.d/$libname-env-vars.sh
        echo "export GFSIO_SRC=$pkgdir/$software" >> /etc/profile.d/$libname-env-vars.sh
        echo "export GFSIO_INC=$prefix/$libdir/include" >> /etc/profile.d/$libname-env-vars.sh
        echo "export GSFIO_LIB=$prefix/$libdir/lib/lib${libname}.a" >> /etc/profile.d/$libname-env-vars.sh
    fi

    libname=ip
    get_version $libname libdir version
    echo for $libname, libdir=$libdir, version=$version
    if [[ "$libdir" != "" && "$version" != "" ]]; then
        [[ -f /etc/profile.d/$libname-env-vars.sh ]] && rm -rf /etc/profile.d/$libname-env-vars.sh
        echo "export IP_VER=$version" >> /etc/profile.d/$libname-env-vars.sh
        echo "export IP_SRC=$pkgdir/$software" >> /etc/profile.d/$libname-env-vars.sh
        echo "export IP_INC4=$prefix/$libdir/include_4" >> /etc/profile.d/$libname-env-vars.sh
        echo "export IP_INC8=$prefix/$libdir/include_8" >> /etc/profile.d/$libname-env-vars.sh
        echo "export IP_INCd=$prefix/$libdir/include_d" >> /etc/profile.d/$libname-env-vars.sh
        echo "export IP_LIB4=$prefix/$libdir/lib/lib${libname}_4.a" >> /etc/profile.d/$libname-env-vars.sh
        echo "export IP_LIB8=$prefix/$libdir/lib/lib${libname}_8.a" >> /etc/profile.d/$libname-env-vars.sh
        echo "export IP_LIBd=$prefix/$libdir/lib/lib${libname}_d.a" >> /etc/profile.d/$libname-env-vars.sh
    fi

    # libname=ip2
    # get_version $libname libdir version
    # echo for $libname, libdir=$libdir, version=$version
    # if [[ "$libdir" != "" && "$version" != "" ]]; then
    #     [[ -f /etc/profile.d/$libname-env-vars.sh ]] && rm -rf /etc/profile.d/$libname-env-vars.sh
    #     echo "export IP_VER=$version" >> /etc/profile.d/$libname-env-vars.sh
    #     echo "export IP_SRC=$pkgdir/$software" >> /etc/profile.d/$libname-env-vars.sh
    #     echo "export IP_INC4=$prefix/$libdir/include_4" >> /etc/profile.d/$libname-env-vars.sh
    #     echo "export IP_INC8=$prefix/$libdir/include_8" >> /etc/profile.d/$libname-env-vars.sh
    #     echo "export IP_INCd=$prefix/$libdir/include_d" >> /etc/profile.d/$libname-env-vars.sh
    #     echo "export IP_LIB4=$prefix/$libdir/lib/lib${libname}_4.a" >> /etc/profile.d/$libname-env-vars.sh
    #     echo "export IP_LIB8=$prefix/$libdir/lib/lib${libname}_8.a" >> /etc/profile.d/$libname-env-vars.sh
    #     echo "export IP_LIBd=$prefix/$libdir/lib/lib${libname}_d.a" >> /etc/profile.d/$libname-env-vars.sh
    # fi
    
    libname=landsfcutil
    if [[ "$libdir" != "" && "$version" != "" ]]; then
        [[ -f /etc/profile.d/$libname-env-vars.sh ]] && rm -rf /etc/profile.d/$libname-env-vars.sh
        echo "export LANDSFCUTIL_VER=$version" >> /etc/profile.d/$libname-env-vars.sh
        echo "export LANDSFCUTIL_SRC=$pkgdir/$software" >> /etc/profile.d/$libname-env-vars.sh
        echo "export LANDSFCUTIL_INC4=$prefix/$libdir/include_4" >> /etc/profile.d/$libname-env-vars.sh
        echo "export LANDSFCUTIL_INCd=$prefix/$libdir/include_d" >> /etc/profile.d/$libname-env-vars.sh
        echo "export LANDSFCUTIL_LIB4=$prefix/$libdir/lib/lib${libname}_4.a" >> /etc/profile.d/$libname-env-vars.sh
        echo "export LANDSFCUTIL_LIBd=$prefix/$libdir/lib/lib${libname}_d.a" >> /etc/profile.d/$libname-env-vars.sh
    fi

    libname=nceppost
    get_version $libname libdir version
    echo for $libname, libdir=$libdir, version=$version
    if [[ "$libdir" != "" && "$version" != "" ]]; then
        [[ -f /etc/profile.d/$libname-env-vars.sh ]] && rm -rf /etc/profile.d/$libname-env-vars.sh
        echo "export POST_VER=$version" >> /etc/profile.d/$libname-env-vars.sh
        echo "export POST_SRC=$pkgdir/$software" >> /etc/profile.d/$libname-env-vars.sh
        echo "export POST_INC=$prefix/$libdir/include" >> /etc/profile.d/$libname-env-vars.sh
        echo "export POST_LIB=$prefix/$libdir/lib/lib${libname}.a" >> /etc/profile.d/$libname-env-vars.sh
    fi

    libname=nemsio
    get_version $libname libdir version
    echo for $libname, libdir=$libdir, version=$version
    if [[ "$libdir" != "" && "$version" != "" ]]; then
        [[ -f /etc/profile.d/$libname-env-vars.sh ]] && rm -rf /etc/profile.d/$libname-env-vars.sh
        echo "export NEMSIO_VER=$version" >> /etc/profile.d/$libname-env-vars.sh
        echo "export NEMSIO_SRC=$pkgdir/$software" >> /etc/profile.d/$libname-env-vars.sh
        echo "export NEMSIO_INC=$prefix/$libdir/include" >> /etc/profile.d/$libname-env-vars.sh
        echo "export NEMSIO_LIB=$prefix/$libdir/lib/lib${libname}.a" >> /etc/profile.d/$libname-env-vars.sh
    fi

    libname=nemsiogfs
    get_version $libname libdir version
    echo for $libname, libdir=$libdir, version=$version
    if [[ "$libdir" != "" && "$version" != "" ]]; then
        [[ -f /etc/profile.d/$libname-env-vars.sh ]] && rm -rf /etc/profile.d/$libname-env-vars.sh
        echo "export NEMSIOGFS_VER=$version" >> /etc/profile.d/$libname-env-vars.sh
        echo "export NEMSIOGFS_SRC=$pkgdir/$software" >> /etc/profile.d/$libname-env-vars.sh
        echo "export NEMSIOGFS_INC=$prefix/$libdir/include" >> /etc/profile.d/$libname-env-vars.sh
        echo "export NEMSIOGFS_LIB=$prefix/$libdir/lib/lib${libname}.a" >> /etc/profile.d/$libname-env-vars.sh
    fi

    libname=sfcio
    get_version $libname libdir version
    echo for $libname, libdir=$libdir, version=$version
    if [[ "$libdir" != "" && "$version" != "" ]]; then
        [[ -f /etc/profile.d/$libname-env-vars.sh ]] && rm -rf /etc/profile.d/$libname-env-vars.sh
        echo "export SFCIO_VER=$version" >> /etc/profile.d/$libname-env-vars.sh
        echo "export SFCIO_SRC=$pkgdir/$software" >> /etc/profile.d/$libname-env-vars.sh
        echo "export SFCIO_INC4=$prefix/$libdir/include_4" >> /etc/profile.d/$libname-env-vars.sh
        echo "export SFCIO_LIB4=$prefix/$libdir/lib/lib${libname}_4.a" >> /etc/profile.d/$libname-env-vars.sh
    fi

    libname=sigio
    get_version $libname libdir version
    echo for $libname, libdir=$libdir, version=$version
    if [[ "$libdir" != "" && "$version" != "" ]]; then
        [[ -f /etc/profile.d/$libname-env-vars.sh ]] && rm -rf /etc/profile.d/$libname-env-vars.sh
        echo "export SIGIO_VER=$version" >> /etc/profile.d/$libname-env-vars.sh
        echo "export SIGIO_SRC=$pkgdir/$software" >> /etc/profile.d/$libname-env-vars.sh
        echo "export SIGIO_INC4=$prefix/$libdir/include_4" >> /etc/profile.d/$libname-env-vars.sh
        echo "export SIGIO_LIB4=$prefix/$libdir/lib/lib${libname}_4.a" >> /etc/profile.d/$libname-env-vars.sh
    fi

    libname=sp
    get_version $libname libdir version
    echo for $libname, libdir=$libdir, version=$version
    if [[ "$libdir" != "" && "$version" != "" ]]; then
        [[ -f /etc/profile.d/$libname-env-vars.sh ]] && rm -rf /etc/profile.d/$libname-env-vars.sh
        echo "export SP_VER=$version" >> /etc/profile.d/$libname-env-vars.sh
        echo "export SP_SRC=$pkgdir/$software" >> /etc/profile.d/$libname-env-vars.sh
        echo "export SP_LIB4=$prefix/$libdir/lib/lib${libname}_4.a" >> /etc/profile.d/$libname-env-vars.sh
        echo "export SP_LIB8=$prefix/$libdir/lib/lib${libname}_8.a" >> /etc/profile.d/$libname-env-vars.sh
        echo "export SP_LIBd=$prefix/$libdir/lib/lib${libname}_d.a" >> /etc/profile.d/$libname-env-vars.sh
    fi

    libname=w3emc
    get_version $libname libdir version
    echo for $libname, libdir=$libdir, version=$version
    if [[ "$libdir" != "" && "$version" != "" ]]; then
        [[ -f /etc/profile.d/$libname-env-vars.sh ]] && rm -rf /etc/profile.d/$libname-env-vars.sh
        echo "export W3EMC_VER=$version" >> /etc/profile.d/$libname-env-vars.sh
        echo "export W3EMC_SRC=$pkgdir/$software" >> /etc/profile.d/$libname-env-vars.sh
        echo "export W3EMC_INC4=$prefix/$libdir/include_4" >> /etc/profile.d/$libname-env-vars.sh
        echo "export W3EMC_INC8=$prefix/$libdir/include_8" >> /etc/profile.d/$libname-env-vars.sh
        echo "export W3EMC_INCd=$prefix/$libdir/include_d" >> /etc/profile.d/$libname-env-vars.sh
        echo "export W3EMC_LIB4=$prefix/$libdir/lib/lib${libname}_4.a" >> /etc/profile.d/$libname-env-vars.sh
        echo "export W3EMC_LIB8=$prefix/$libdir/lib/lib${libname}_8.a" >> /etc/profile.d/$libname-env-vars.sh
        echo "export W3EMC_LIBd=$prefix/$libdir/lib/lib${libname}_d.a" >> /etc/profile.d/$libname-env-vars.sh
    fi

    libname=w3nco
    get_version $libname libdir version
    echo for $libname, libdir=$libdir, version=$version
    if [[ "$libdir" != "" && "$version" != "" ]]; then
        [[ -f /etc/profile.d/$libname-env-vars.sh ]] && rm -rf /etc/profile.d/$libname-env-vars.sh
        echo "export W3NCO_VER=$version" >> /etc/profile.d/$libname-env-vars.sh
        echo "export W3NCO_SRC=$pkgdir/$software" >> /etc/profile.d/$libname-env-vars.sh
        echo "export W3NCO_LIB4=$prefix/$libdir/lib/lib${libname}_4.a" >> /etc/profile.d/$libname-env-vars.sh
        echo "export W3NCO_LIB8=$prefix/$libdir/lib/lib${libname}_8.a" >> /etc/profile.d/$libname-env-vars.sh
        echo "export W3NCO_LIBd=$prefix/$libdir/lib/lib${libname}_d.a" >> /etc/profile.d/$libname-env-vars.sh
    fi

    libname=wgrib2
    get_version $libname libdir version
    echo for $libname, libdir=$libdir, version=$version
    if [[ "$libdir" != "" && "$version" != "" ]]; then
        [[ -f /etc/profile.d/$libname-env-vars.sh ]] && rm -rf /etc/profile.d/$libname-env-vars.sh
        echo "export WGRIB2_VER=$version" >> /etc/profile.d/$libname-env-vars.sh
        echo "export WRFIO_SRC=$pkgdir/$software" >> /etc/profile.d/$libname-env-vars.sh
        echo "export WRFIO_INC=$prefix/$libdir/include" >> /etc/profile.d/$libname-env-vars.sh
        echo "export WRFIO_LIB=$prefix/$libdir/lib/lib${libname}.a" >> /etc/profile.d/$libname-env-vars.sh
    fi

    libname=wrf_io
    get_version $libname libdir version
    echo for $libname, libdir=$libdir, version=$version
    if [[ "$libdir" != "" && "$version" != "" ]]; then
        [[ -f /etc/profile.d/$libname-env-vars.sh ]] && rm -rf /etc/profile.d/$libname-env-vars.sh
        echo "export WRFIO_VER=$version" >> /etc/profile.d/$libname-env-vars.sh
        echo "export WRFIO_SRC=$pkgdir/$software" >> /etc/profile.d/$libname-env-vars.sh
        echo "export WRFIO_INC=$prefix/$libdir/include" >> /etc/profile.d/$libname-env-vars.sh
        echo "export WRFIO_LIB=$prefix/$libdir/lib/lib${libname}.a" >> /etc/profile.d/$libname-env-vars.sh
    fi

fi
