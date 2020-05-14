#!/bin/bash

# whether to use Lmod or tcl module management system
export LMOD=N

# Compiler/MPI combination
export COMPILER="gcc/system"
#export COMPILER="gnu/8.2.1"
export MPI="openmpi/3.1.4"

# This tells jedi-stack how you want to build the compiler and mpi modules
# valid options include:
# native-module: load a pre-existing module (common for HPC systems)
# native-pkg: use pre-installed executables located in /usr/bin or /usr/local/bin,
#             as installed by package managers like apt-get or hombrewo.
#             This is a common option for, e.g., gcc/g++/gfortrant
# from-source: This is to build from source
export COMPILER_BUILD="native-module"
export MPI_BUILD="native-module"

# Build options
export PREFIX=$OPT
export USE_SUDO=N
export PKGDIR=pkg
export LOGDIR=buildscripts/log
export OVERWRITE=N
export NTHREADS=4
export   MAKE_CHECK=Y
# NCI
# some NetCDF tests use MPI and MPI jobs cannot be launched from Gadi login nodes;
# so disable tests
# N.B. make sure tests are run manaully after the jedi-stack build finishes
export   MAKE_CHECK_NETCDF=N
export MAKE_VERBOSE=Y
export   MAKE_CLEAN=N
export DOWNLOAD_ONLY=N
export STACK_EXIT_ON_FAIL=Y
export WGET="wget -nv"

# Minimal JEDI Stack
export      STACK_BUILD_CMAKE=N
export       STACK_BUILD_SZIP=N
export    STACK_BUILD_UDUNITS=N
export       STACK_BUILD_ZLIB=N
export     STACK_BUILD_LAPACK=N
export    STACK_BOOST_HEADERS=N
export     STACK_BUILD_EIGEN3=N
export       STACK_BUILD_HDF5=N
export    STACK_BUILD_PNETCDF=N
export     STACK_BUILD_NETCDF=Y
export      STACK_BUILD_NCCMP=N
export        STACK_BUILD_NCO=N
export    STACK_BUILD_ECBUILD=Y
export      STACK_BUILD_ECKIT=Y
export      STACK_BUILD_FCKIT=Y
export        STACK_BUILD_ODB=Y
export        STACK_BUILD_ODC=N
export    STACK_BUILD_ODYSSEY=N
export    STACK_BUILD_BUFRLIB=Y

# Optional Additions
export           STACK_BUILD_PIO=N
export        STACK_BUILD_PYJEDI=Y
export      STACK_BUILD_NCEPLIBS=Y
export        STACK_BUILD_JASPER=N
export     STACK_BUILD_ARMADILLO=N
export        STACK_BUILD_XERCES=N
export        STACK_BUILD_TKDIFF=Y
export          STACK_BOOST_FULL=N
export          STACK_BUILD_ESMF=N
export      STACK_BUILD_BASELIBS=N
export     STACK_BUILD_PDTOOLKIT=Y
export          STACK_BUILD_TAU2=Y

