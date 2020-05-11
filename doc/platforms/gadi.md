# Building the JEDI software stack for NCI

To build and install JEDI software stack on Gadi I followed the README.md that is on https://github.com/JCSDA/jedi-stack closely.

## Step 1: Set up Basic Environment

1. Most of the software packages mentioned in README.md are already available on Gadi,
   * Some are available from /bin (e.g. wget, curl); others are available through modulefiles
   * Note `setup_environment.sh` is only for a Linux machine with a bare minimum software stack and where you have the root privilege; so for Gadi this script was not used
   * I used Python3 as recommended by Mark Miesch
   * the modulefile for MKL sets up environments for ScaLAPACK, LAPACK and BLAS
   * git-flow is not needed to build jedi-stack
   * Doxygen is available from /bin; I asked Wenming to install Graphviz under ~access (**ToDo.** Wenming)
   * only gdb (GNU debugger) is available on Gadi; others (kdbg and valgrind) are not; Yaswant Pradhan (UKMO) advises we don't need them but there might be problems later (?)
   * I'm using parallel versions of HDF5 and NETCDF: `hdf5/1.10.5p` and `netcdf/4.7.1p`

2. Since I do not have root privilege I am installing modulefiles on `/g/data/dp9/jtl548/opt/modules`
   * I put `export OPT=/g/data/dp9/jtl548/opt/modules` in my .bash_profile. (**ToDo.** This needs changing when deploying jedi-stack for a general use)

## Step 2: Configure Build

1. Initially using GNU compiler and Intel MPI: for this I created a new configuration file, `buildscripts/config/config_nci_gnu8.2.1-openmpi3.1.4.sh`.

## Step 3: Set Up Compiler, MPI, and Module System

`setup_modules.sh` copies all modulefiles to $OPT/modulefiles. Some of these modulefiles are needed during the jedi-stack build and others are needed to set up JEDI run-time environment. Modulefiles are separated into subdirectories underneath $OPT/modulefiles according to their dependence on compiler and MPI. Following is a command issued for NCI using Gnu compilers with Open MPI,

```
cd buildscripts
setup_modules.sh nci_gnu8.2.1-openmpi3.1.4
```

Make sure to enter 'Y' when the script asks,
```
WARNING: COMPILER VERSION $COMPILER APPEARS TO BE INCORRECT!
CONTINUE ANYWAY? ANSWER Y OR N
```

## Step 4: Build JEDI Stack

### tcl module management system

Based on the advice of Mark I decided to use `feature/discover` branch. The module management system used on discover is tcl (not Lmod) so this is compatible with our modules.

After running `setup_modules.sh` I have edited relevant `libs/build_*` scripts.

Modulefiles created during the build are loaded by the individual `libs/build_*` scripts and the modulefiles contain lines adding appropriate paths to MODULEPATH (jedi-*????).

### NetCDF

* Based on advice from Mark Miesch initially I decided to use the native pnetcdf and netcdf builds rather than building my own pnetcdf and netcdf. However it turned out that NCI did not build its native netcdf (e.g. `netcdf/4.7.1p`) with pnetcdf parallel IO support.
* Then Mark advised me that netcdf with pnetcdf parallel IO support is not needed unless we would be working with older netcdf formats (email from Mark, 12/3/20). So at this point I decided to use the native netcdf which lacks the pnetnet-enabled parallel IO support
* Subsequently when building ufo-bundle ecbuild failed as it could not find the native netcdf library: the way NCI named the netcdf libraries was unusual and ecbuild's `FindNetCDF4.cmake` failed to find the libraries. To get around this problem I switched on the building of netcdf so that the library is built with the usual names
* When running `make check` to test for the correctness of netcdf build you might see warning and error messages like,
  ```
  [gadi-login-01.gadi.nci.org.au:07121] shmem: posix: file name search - max attempts exceeded.cannot continue with posix.
  --------------------------------------------------------------------------
  WARNING: There was an error initializing an OpenFabrics device.

  Local host:   gadi-login-03
  Local device: mlx5_0
  --------------------------------------------------------------------------
  2       2.14373 5.00875e+08
  [gadi-login-03.gadi.nci.org.au:14295] 1 more process has sent help message help-mpi-btl-openib.txt / error in device init
  [gadi-login-03.gadi.nci.org.au:14295] Set MCA parameter "orte_base_help_aggregate" to 0 to see all help / error messages
  ```
  The first message is caused by a limit on shared memory namespace when running a non-batch job. The second message is caused by the version of the OpenMPI not supporting Gadi's interconnect. This error occurs because `make check` uses MPI launcher - mpirun or mpiexec - to run MPI test jobs on a Gadi login node. To run the MPI tests of netcdf C library build you will need to modify the test script. Here's an instruction on how to modify the test script,

  In `<TOP_DIR_JEDI_STACK>/pkg/netcdf-c-4.7.0/build/nc_test4/run_par_test.sh` change the following line,
  ```
  mpiexec -n 16 ./tst_parallel3
  ```
  to,
  ```
  qsub -q express -l walltime=00:05:00,mem=192G,ncpus=48 -l wd -l storage=scratch/access+scratch/dp9+gdata/access+gdata/dp9+gdata/hh5 -V -- mpiexec -n 16 ./tst_parallel3
  ```

  The script, `run_par_test.sh` will run as a batch job and also it will use OpenMPI that uses Gadi interconnect.

  Then run `make ckeck`

  See https://track.nci.org.au/servicedesk/customer/portal/5/HELP-169370 for further details. 

  In summary, for netcdf use `MAKE_CHECK_NETCDF=N` in NCI configuration (this is default for the NCI configuration, `config_nci_gnu8.2.1-openmpi3.1.4.sh`). After the jedi-stack build completes follow the instruction above to run netcdf C parallel tests.

### HDF5

I tried to build hdf5 as the NCI-installed hdf5 libraries had unusual names - similar to netcdf. However there was problem with shmem and fabric (?). So I decided to use the native hdf5

### Atlas

This package was not built based on the advice from Mark (email from Mark on 17/3/20)

### ODC, Odyssesy and Armadillo

Based on advice from Mark Miesch (email from Mark on 6/3/20) I decided not to build ODC, Odyssey and Armadillo,
   * if and when I decide to build ODC (JCSDA ODC reporitory is private which means I don't have access to it using my GitHub account) and Odyssey there is a partially completed modulefile for Odyssey (modulefiles_tcl/mpi/gcc/system/openmpi/4.0.2/odyssey/jcsda-develop).

### PIO

Parallel IO (pio) library was not built as this is only needed in MPAS model bundle

### pyjedi

`libs/build_pyjedi.sh` builds and installs,
  * Python3 packages under $OPT/pyjedi
  * py-ncepbufr - used to read NCEP Bufr files

See email from Mark on 17/3/20 and more recent on 30/4/20 informing that Python2 was dropped from JEDI.

### ESMF

This package was not built based on the advice from Mark (see email from Mark on 17/3/20).

### Baselibs

This package was not built based on the advice from Mark (see email from Mark on 17/3/20).

### Native libraries

Some of the pre-requisite software packages used by JEDI are a little older than what are available on Gadi. The list of versions required by jedi-stack and those which are available on Gadi follows (only those packages which have different versions),

| Software | Version used in jedi-stack | Version available on Gadi | |
| --- | --- | --- | --- |
| cmake | 3.13.0 | 3.16.2 | |
| LAPACK | 3.7.0 | uses Intel MKL and 2020.0.166 not sure what version of LAPACK | |
| boost header and full library | 1.68.0 | 1.71.0 | |
| eigen | 3.3.5 | 3.3.7| |
| nccmp | 1.8.2.1 | 1.8.5.0 | |
| jasper | 1.900.1 | 2.0.16 | |
| xerces | 3.1.4 | 3.2.2 | |
| nco | 4.7.9 | 4.9.2 | |

### Compile-time environment

Before running `build_stack.sh` the top-level jedi modulefile location needs to be prepended to MODULEPATH as well as some modulefiles are loaded to provide tools needed during the build,

```
unset PYTHONPATH                  # when a Python interpreter starts PYTHONPATH is added to sys.path - allow clean module search path
module purge
module use $OPT/modulefiles/core  # The path to the top-level modulefile
module load gcc/system            # GNU compiler
module load openmpi/3.1.4         # or openmpi/4.0.2 - when building nceplibs - e.g. mpif90
module load cmake/3.16.2          # this is to enable the use of later version of CMake which is compatible with bufrlib CMakeLists.txt; **Note.** `libs/build_bufrlib.sh` doesn't have a `module load cmake/<version>` so the module load has to be done outside of the script
module load git/2.24.1            # this newer modulefile allows the use of git-lfs
module load python3/3.7.4         # use this version of Python3 unless packages use other Python versions
module load python3-as-python     # to allow both python and python3 in script shebang
```

Following is a command issued for NCI using Gnu compilers with Open MPI,

```
cd buildscripts
build_stack.sh nci_gnu8.2.1-openmpi3.1.4.sh > out.txt 2>err.txt &
```
### Installation directory

After a successful build/installation you should see the following directories under $OPT (=/g/data/dp9/jtl548/opt/modules in my case),

```
core/  gcc-system/  modulefiles/ pyjedi/
```
### Possible problems during build

* For a complete new build you may want to delete all files underneath <TOP_DIR_JEDI_STACK>/pkg
* On a rare occasion during jedi-stack build (or even the building of subsystem) job may fail without any reason. Re-running seems to solve the problem.

## Remaining Issues

### Changes needing to be made

* In various tcl modulefiles there is a line, `set base /g/data/dp9/jtl548/opt/modules/$comp/$mpi/$name/$ver`; use $OPT to make it easier to handle the building script over to Wenming
* In some limited places of the libs/build_* scripts I had to make small changes. Would it be better to introduce another environment variable to take care of site-specific processing: e.g. `SITE=nci`
* odc is not a public repository and so durng jedi-stack build the script cannot reach odb repo
* `/g/data/dp9/jtl548/opt/modules/gcc-system/openmpi-4.0.2/odyssey/jcsda-develop/lib/python3.7/site-packages` vs `/g/data/dp9/jtl548/opt/modules/gcc-system/openmpi-4.0.2/odb-api/0.18.1.r2/lib/python2.7/site-packages`: why is one built using Python3.7 and another Python2.7?
* When I get around building pio keep following points in mind,
  * libs/build_pio.sh fails as there appears to be problems with using native NetCDF: some environment variables are not available. I may need to build netcdf, hdf5 and pnetcdf
  * also I need to create `modulefiles_tcl/mpi/gcc/system/openmpi/4.0.2/pio/2.4.4`
* Compile-time environment can be set up in `libs/build_*.sh` or directly in the shell in which the build takes place. For portability it's better not to modify the scripts.  
* During the pyjedi build Python2 packages were installed in the right location: `$HOME/.local/lib/python2.7/site-packages`. However during the Python3 build some packages seem to have ended up in the Python2 site-packages directory instead of the directory for Python3. Or it could be that packages are shared between the 2 versions of Python. Ask Milton.
  * there were error messages like,
    ```
    ERROR: matplotlib 2.2.5 requires backports.functools-lru-cache, which is not installed.
    ERROR: matplotlib 2.2.5 requires subprocess32, which is not installed.
    ```
* Do I need to build my own NCO as netcdf is now built?

### Scripts and configurations needing to be rolled back

* In `config/config_nci_gnu8.2.1-openmpi4.0.2.sh` `OVERWRITE` is set to `N` to enable faster build. This should be changed back to `Y`

# Testing jedi-stack

## Build and test ufo-bundle

Source used for test is https://github.com/JCSDA/ufo-bundle develop branch at 25d25ff0

To set up jedi-stack environment,

```
unset PYTHONPATH                                            # when a Python interpreter starts PYTHONPATH is added to sys.path - allow clean module search path
module purge
module use /g/data/dp9/jtl548/opt/modules/modulefiles/core  # prepend this location to MODULEPATH - most jedi-stack modulefiles are
module use /g/data/dp9/jtl548/opt/modules/modulefiles/apps  # prepend this location to MODULEPATH - where top-level modulefile for setting jedi-stack is
module load jedi/gcc-system_openmpi-3.1.4                   # top-level modulefile
```

ecbuild and make succeed. CTest nearly succeeds with 2 failures,

```
99% tests passed, 2 tests failed out of 597

Subproject Time Summary:
fckit    =   4.95 sec*proc (13 tests)
gsw      =   0.25 sec*proc (2 tests)
ioda     =  18.46 sec*proc (15 tests)
oops     = 150.08 sec*proc (158 tests)
saber    = 286.89 sec*proc (160 tests)
ufo      = 517.85 sec*proc (132 tests)

Label Time Summary:
atlas            =  59.07 sec*proc (117 tests)
download_data    =  18.32 sec*proc (2 tests)
executable       = 174.75 sec*proc (212 tests)
fortran          =   8.37 sec*proc (33 tests)
mpi              = 284.60 sec*proc (120 tests)
openmp           = 291.99 sec*proc (118 tests)
script           = 844.49 sec*proc (383 tests)

Total Test time (real) = 1045.45 sec

The following tests FAILED:
	282 - test_qg_4dvar_rpcg (Failed)
	283 - test_qg_4dvar_saddlepoint (Failed)
```

### Remaining problems

*  Following error message is found,
   ```
   -- Could NOT find FFTW (missing: FFTW_INCLUDE_DIRS FFTW_LIBRARIES double)
   -- Could NOT find package FFTW required for feature FFTW -- Provide FFTW location with -DFFTW_PATH=/...
   -- Feature FFTW was not enabled (also not requested) -- following required packages weren't found: FFTW
   ```
   FFTW3 library is available on Gadi, `fftw3-mkl/2019.3.199` but the modulefile does not seem to export all the necessary environment variables: see `modulefile/mpi/compilerName/compilerVersion/mpiName/mpiVersion/fftw/fftw.lua`

## Build and test fv3-bundle

Source used for test is https://github.com/JCSDA/fv3-bundle develop branch at 2c3d9dff

Same runtime environment as for ufo-bundle.

ecbuild and make succeed. CTest nearly succeeds with 2 failures,

```
99% tests passed, 2 tests failed out of 699

Label Time Summary:
atlas            =  31.18 sec*proc (117 tests)
download_data    =  50.57 sec*proc (2 tests)
executable       = 165.48 sec*proc (214 tests)
fckit            =   1.62 sec*proc (13 tests)
femps            =  15.56 sec*proc (1 test)
fortran          =   3.30 sec*proc (33 tests)
fv3-jedi         = 1413.45 sec*proc (104 tests)
fv3jedi          = 1420.05 sec*proc (105 tests)
ioda             =  16.07 sec*proc (15 tests)
mpi              = 1781.79 sec*proc (193 tests)
oops             =  80.00 sec*proc (158 tests)
openmp           = 348.93 sec*proc (118 tests)
saber            = 402.08 sec*proc (160 tests)
script           = 2197.10 sec*proc (483 tests)
ufo              = 446.60 sec*proc (130 tests)

Total Test time (real) = 2420.15 sec

The following tests FAILED:
	283 - test_qg_4dvar_saddlepoint (Failed)
	621 - test_fv3jedi_linvarcha_gfs (Failed)
```
