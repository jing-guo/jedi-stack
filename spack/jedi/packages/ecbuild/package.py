# Copyright 2013-2020 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: Apache-2.0

from spack import *

class Ecbuild(CMakePackage):
    """A CMake-based build system, consisting of a collection of CMake macros and functions that ease the managing of software build systems."""

    homepage = "https://software.ecmwf.int/wiki/display/ecbuild"
    git = "https://github.com/JCSDA/ecbuild.git"
    url = "https://github.com/JCSDA/ecbuild/archive/3.3.0.jcsda3.tar.gz"

    maintainers = ['rhoneyager', 'mmiesch']

    version('3.3.2.jcsda1', commit='9c7db0ec79a21fa8ab8eeae77e2e83ff14e9d21e')
    # mismatched ecmwf / jcsda commit
    # version('3.3.2', commit='362e3d93d331b62bf8b6cf515db253c9e9c50daa')
    version('3.3.1', commit='34f8362771aef4fc9debd886011fa188a120522a')
    version('3.3.0.jcsda3', commit='e83000c23ad505f49ce060b27c519c48a35bf5ac')
    version('3.3.0.jcsda2', commit='a2c8c684025b0362b68ea0b6f557ad2774290be4')
    version('3.3.0.jcsda1', commit='7cb4d5588d26bb6ecd59a4445572f7ce1bc9bd84')
    version('3.3.0', commit='a981ba52b0765b8e4c7a28210fc804fb772030e9')
    version('3.2.0', commit='9dcf4c6f80c2cbd349f110af53c0256f1687d160')
    version('3.1.0.jcsda3', commit='ee7eeafe35d366b6febfa2004ef912cfe6a435dd')
    version('3.1.0.jcsda2', commit='4e504579d7866aaa2227c58eedeb474fdb9d4659')
    version('3.1.0.jcsda1', commit='b1983e309552b87a7d62e556b9f0aea7eb5dc393')
    version('3.1.0', commit='457e7ea1c78dcfe0cef51e6ea886b7c53a0c94c3')

    depends_on('cmake @3.10:', type=('build', 'run', 'link'))

    def cmake_args(self):
        return []

