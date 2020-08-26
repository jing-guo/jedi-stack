# Platforms

Here are are tips for building the jedi-stack on particular Platforms

## <a name="MacPython"></a>Setting up python for Mac OSX
It is recommended for now to skip the automatic build of the pyjedi package. This has been shut off by default in the mac configuration file. It is also recommended to use miniconda for python2 and python3.

For miniconda, get the downloads on the site: https://docs.conda.io/en/latest/miniconda.html. Select the 64-bit bash installer for both python 2.7 and 3.7. These each download a script to install miniconda on your Mac. Run each script as:
~~~~~~~
sh Miniconda2-latest-MacOSX-x86_64.sh
sh Miniconda3-latest-MacOSX-x86_64.sh
~~~~~~~

When prompted allow the install to go into your home directory, and allow the script to modify your .bash_profile file. Edit your .bash_profile file and make sure that your PATH is being set the way you want it. Keep in mind that for now the ODB API python interface only works with python 2.7 (so you should make sure that "python" will be found in your miniconda2 area).

Once you have miniconda2 and 3 installed, run the conda command to install extra python packages you will need for JEDI. For both miniconda2 and 3, run:
~~~~~~~
conda install setuptools
conda install wheel
conda install netcdf4
conda install matplotlib
conda install pycodestyle
conda install autopep8
conda install swig
conda install numpy
conda install scipy
conda install pyyaml
conda install sphinx
~~~~~~~

Then, build the ncepbufr python packages. Again for both miniconda2 and 3, run:
~~~~~~~
git clone https://github.com/JCSDA/py-ncepbufr.git # Only need to do this once. The build/install processes for both
                                                   # python2 and 3 can be run from the same clone of py-ncepbufr.

cd py-ncepbufr
python setup.py build
python setup.py install
~~~~~~~

## Mac OSX Clang environment module
One result of the build process for Mac OSX is that a module script has been installed for setting up your environment for using Clang on the Mac. This can be accessed by running:
~~~~~~~
module purge                        # clear out the environment
module load jedi/clang-openmpi      # set environment for subsequent JEDI builds on the Mac using Clang and OpenMPI
module list
~~~~~~~

## Gentoo

The ``gentoo`` system setting is designed for building Intel toolchains on systems like [Gentoo Linux](https://gentoo.org/get-started/),
where the base system and all JEDI dependencies are compiled using GCC and installed in the `/usr` directory.  In order to also build JEDI packages with
Intel compilers, all Fortran packages that provide compiled modules must be independently compiled
with the Intel `ifort` compiler.

To setup environment, choose a modules home directory.  This can be anywhere, but a common location is `$HOME/opt/modules`.  Also the Intel compilers must be installed to a location pointed to by the `INTEL_ROOT` environment variable.  We assume licenses are available under the `$INTEL_ROOT/licenses` path, but the path can also be supplied via `INTEL_LICENSE_FILE` environment variable.
~~~~~~~~~
$ export INTEL_ROOT=<path-to-intel-root>
$ export JEDI_OPT=$HOME/opt/modules
$ buildscipts/setup_environment.sh gentoo
$ buildscipts/setup_modules.sh gentoo
$ buildscipts/build_stack.sh gentoo
~~~~~~~~~

The enthronement setup with `setup_environment.sh gentoo` generates a `$HOME/.jedi-stack-bashrc` with all the environment
variables necessary for configuring the JEDI modules, based on the supplied `JEDI_OPT`.  This script can then be sourced in `.bashrc` if desired:
~~~~~~~~~
source $HOME/.jedi-stack-bashrc
~~~~~~~~~

Now load intel-impi modules under the `jedi` prefix:
~~~~~~~~~
$ module load jedi/intel-impi
~~~~~~~~~

## S4 (SSEC)

S4 only supports intel modules.  But, when building JEDI, you must link to newer gcc headers and libraries in order to enable C++-14 support.  You may not be able to build JEDI unless you use these flags for the stack as well as the JEDI code itself.  See the [S4 configuration file for details](../buildscripts/config/config_S4.sh).

Another important tip is that you cannot load the intel compiler module until you have loaded the intel license module.  Furthermore, the default version of python is 2.7 so it is recommended that you load the miniconda module for python3.  So, before running `build_stack.sh`, we recommend you load the following modules:

```bash
module load license_intel miniconda
```

When building the jedi-code itself, it is recommended that you use the [S4 toolchain located in the jedi-cmake repository](https://github.com/JCSDA/jedi-cmake/blob/develop/cmake/Toolchains/jcsda-S4-Intel.cmake):

```bash
ecbuild --toolchain=<path>/jedi-cmake/cmake/Toolchains/jcsda-S4-Intel.cmake <path-to-bundle>
```

This will add the flags necessary for C++-14 support and it will also identify `srun` as the preferred executable for parallel MPI processes.

## Discover (NCCS)

When building the intel stack on Discover, it is recommended that you use the `comp/intel/19.1.0.166` together with the `comp/gcc/9.2.0` module.  Intel uses gcc headers and libraries to provide support for `c++-14` and later and the default `gcc` is not sufficient to provide this.

The current `jedi/intel-impi/19.1.0.166` module on Discover auto-loads the `comp/gcc/9.2.0` module so if you are using that you do not have to load it explicitly.  But, if you are starting from scratch, you should edit your intel module to auto-load a gnu module that is compatible and that provides C++-14 support.

It also helps to load up-to-date versions of cmake, git and python before you run `build_stack.sh`.   Furthermore, since the top-level metamodules are located is a slightly different place than on other systems (`$JEDI_OPT/modulefiles/apps`) it is useful to append your modulepath as shown here.  So, in short, we recommend you execute the following commands before running `build_stack.sh`:

```
module use $JEDI_OPT/modulefiles
module use $JEDI_OPT/modulefiles/core
module load git python/GEOSpyD cmake
```

For most of the libraries, it is also advisable to use the `-m64` flag when compiling with intel, as specified in the [configuration file](../buildscripts/config/config_Discover.sh).  However, this flag should be omitted for bufrlib and for jedi itself.

For hdf5 in particular, the following flags are recommended

```bash
export CFLAGS="-w -g -O -fPIC -m64"
export CXXFLAGS="-w -g -O -fPIC -m64"
export FFLAGS="-fPIC -g -O -m64"
export F90FLAGS="-fPIC -g -O -m64"
export FCFLAGS="$FFLAGS"
```

## Cheyenne (NCAR)

One thing to watch out for with Cheyenne is that native modules often have the same names as the modules in the jedi-stack(e.g. `pnetcdf`, `hdf5`...) and they are set up to be the defaults.  So make sure you're using the modules you want in the build.

Recommended native modules to load before building the stack are:
```bash
module load cmake git python
```