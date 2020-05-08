#!/bin/bash

# These are python tools for use with JEDI

set -ex

name="pyjedi"

[[ $USE_SUDO =~ [yYtT] ]] || ! $MODULES && prefix=${PYJEDI_ROOT:-"/usr/local"} \
	                  || prefix="$HOME/.local"

#####################################################################
# Python Package installs
#####################################################################

# force the use of Python3 before installing Python3 packages
module unload python2 python3
module load python3/3.7.4

# NCI
# pip-install first checks the system package location to see if packages are
# needed to be upgraded; --ignore-installed forces pip-install to not do this check.
# To be safe use --force-reinstall to do a fresh install
$SUDO python3 -m pip install --force-reinstall --ignore-installed --prefix ${OPT}/pyjedi pip setuptools
$SUDO python3 -m pip install --force-reinstall --ignore-installed --prefix ${OPT}/pyjedi numpy
$SUDO python3 -m pip install --force-reinstall --ignore-installed --prefix ${OPT}/pyjedi wheel netCDF4 matplotlib
$SUDO python3 -m pip install --force-reinstall --ignore-installed --prefix ${OPT}/pyjedi pandas
$SUDO python3 -m pip install --force-reinstall --ignore-installed --prefix ${OPT}/pyjedi pycodestyle
$SUDO python3 -m pip install --force-reinstall --ignore-installed --prefix ${OPT}/pyjedi autopep8
$SUDO python3 -m pip install --force-reinstall --ignore-installed --prefix ${OPT}/pyjedi cffi
$SUDO python3 -m pip install --force-reinstall --ignore-installed --prefix ${OPT}/pyjedi pycparser
$SUDO python3 -m pip install --force-reinstall --ignore-installed --prefix ${OPT}/pyjedi pytest

#####################################################################
# ncepbufr for python
#####################################################################

cd ${JEDI_STACK_ROOT}/${PKGDIR:-"pkg"}
git clone https://github.com/JCSDA/py-ncepbufr.git 
cd py-ncepbufr 

# force the use of Python3 before installing Python3 packages
module unload python2 python3
module load python3/3.7.4

CC=gcc python3 setup.py build 
if [[ $USE_SUDO =~ [yYtT] ]]
then
    $SUDO python3 setup.py install
else
    python3 setup.py install --prefix ${OPT}/pyjedi
fi

exit 0
