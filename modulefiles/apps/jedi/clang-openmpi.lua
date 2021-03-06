help([[
Load environment for running JEDI applications with clang/gfortran compilers and OpenMPI.
]])

local pkgName    = myModuleName()
local pkgVersion = myModuleVersion()
local pkgNameVer = myModuleFullName()

conflict(pkgName)

load("jedi-clang")
load("szip/2.1.1")
load("jedi-openmpi/4.0.3")

load("hdf5")
load("pnetcdf")
load("netcdf")

load("lapack")
load("boost-headers")
load("eigen")
load("bufrlib")

load("ecbuild")

load("nccmp")

setenv("CC","mpicc")
setenv("FC","mpifort")
setenv("CXX","mpicxx")
setenv("LD","mpicc")

whatis("Name: ".. pkgName)
whatis("Version: ".. pkgVersion)
whatis("Category: Application")
whatis("Description: JEDI Environment with clang/OpenMPI")
