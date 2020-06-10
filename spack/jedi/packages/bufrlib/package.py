# Copyright 2013-2020 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: Apache-2.0

from spack import *

class Bufrlib(CMakePackage):
    """NCEP BUFRLIB with a modern CMake build system."""

    homepage = "https://github.com/JCSDA/bufrlib"
    git = "https://github.com/JCSDA/bufrlib.git"
    url = "https://github.com/JCSDA/bufrlib/archive/v11.3.0.2.tar.gz"

    maintainers = ['rhoneyager', 'mmiesch', 'markjolah']

    version('11.3.0.2', commit='9f662a2261026c67413af5960b97eb89bc46826c')
    version('11.3.0.1', commit='9db11390b7579ce03a855bbb3b4bb43afc91a596')
    version('master', branch='master')

    depends_on('cmake @3.15:', type=('build', 'run', 'link'))

    variant('shared', default=False, description='Builds a shared version of the library')
    variant('static', default=True, description='Builds a static version of the library')
    variant('ipo', default=True, description='Enable interprocedural optimization if available')

    def cmake_args(self):
        res = []
        if '+shared' in self.spec:
            res.append('-DBUILD_SHARED_LIBS=ON')
        else:
            res.append('-DBUILD_SHARED_LIBS=OFF')
        
        if '+static' in self.spec:
            res.append('-DBUILD_STATIC_LIBS=ON')
        else:
            res.append('-DBUILD_STATIC_LIBS=OFF')

        if '+ipo' in self.spec:
            res.append('-DOPT_IPO=ON')

        return res

