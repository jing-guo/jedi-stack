help([[
]])

local pkgName    = myModuleName()
local pkgVersion = myModuleVersion()
local pkgNameVer = myModuleFullName()

conflict(pkgName)

try_load("cmake")

local opt = os.getenv("JEDI_OPT") or os.getenv("OPT") or "/opt/modules"

local base = pathJoin(opt,"core",pkgName,pkgVersion)

prepend_path("PATH", pathJoin(base,"bin"))

setenv("ECBUILD_PATH",base)
setenv("ECBUILD_DIR", pathJoin(base,"share/ecbuild/cmake"))

whatis("Name: ".. pkgName)
whatis("Version: " .. pkgVersion)
whatis("Category: Software")
whatis("Description: ecbuild (A CMake-based build system from ECMWF)")
