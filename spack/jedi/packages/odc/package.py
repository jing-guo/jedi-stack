# Copyright 2013-2020 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: Apache-2.0

import os
from spack import *

class Odc(CMakePackage):
    """ECMWF encoding and decoding of observational data in ODB2 format"""

    homepage = "https://software.ecmwf.int/wiki/display/ODC"
    git = "https://github.com/JCSDA/odc.git"
    url = "https://github.com/JCSDA/odc/archive/1.0.3.jcsda1.tar.gz"

    maintainers = ['rhoneyager', 'mmiesch', 'srherbener']

    version('release-stable', branch='release-stable')
    version('develop', branch='develop')
    version('1.0.3.jcsda1', commit='45dc5cdb261fd522a0bcc9922b0cdfbc7e10fd3b')
    version('1.0.3', commit='8a120ebc744778248dda0267094cbf9aaa9d7246')
    version('1.0.2.jcsda1', commit='9b4e25349f8f73509235de9bfd203a7d83d779e9')
    version('1.0.2', commit='6b75e9f666251fa4d98d6b791816cbabd9d29caa')

    depends_on('cmake @3.6:')
    depends_on('ecbuild @3.3.2.jcsda1:', type=('build', 'run', 'link'))
    depends_on('eckit @1.11.6:', type=('build', 'run', 'link'))

    variant('fortran', default=False)

    def cmake_args(self):
        res = [
                self.define_from_variant('ENABLE_FORTRAN', 'fortran')
                ] 
        res.append('-DCMAKE_MODULE_PATH=' + self.spec['ecbuild'].prefix + '/share/ecbuild/cmake')
        #res.append('-DCMAKE_MODULE_PATH='+os.environ['CMAKE_MODULE_PATH'])
        return res

