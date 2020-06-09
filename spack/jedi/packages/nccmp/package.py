# Copyright 2013-2020 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack import *


class Nccmp(Package):
    """Compare NetCDF Files"""
    homepage = "https://gitlab.com/remikz/nccmp"
    git = "https://gitlab.com/remikz/nccmp.git"

    version('1.8.7.0', commit='d302c3eda15b474ca0ed6a8380c494aa8cbb914f')

    # Bad bash
    patch('test_nccmp_template.sh.patch', level=1)

    # NetCDF-C bugs
    # See https://gitlab.com/remikz/nccmp/-/issues/10
    # Known error since v4.5!
    # Suppressing these failures since we do not use these features.
    patch('test_61.patch', level=1)
    patch('test_63.patch', level=1)

    depends_on('netcdf-c')

    def install(self, spec, prefix):
        # Configure says: F90 and F90FLAGS are replaced by FC and
        # FCFLAGS respectively in this configure, please unset
        # F90/F90FLAGS and set FC/FCFLAGS instead and rerun configure
        # again.
        env.pop('F90', None)
        env.pop('F90FLAGS', None)

        configure('--prefix=%s' % prefix)
        make()
        make("check")
        make("install")
