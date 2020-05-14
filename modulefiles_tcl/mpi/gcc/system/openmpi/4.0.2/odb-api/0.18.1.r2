#%Module######################################################################
##
##    odb-api
##
proc ModulesHelp { } {
        puts stderr "Load odb-api"
}

set comp gcc-system
set mpi openmpi-4.0.2
set name odb-api
set ver 0.18.1.r2
set base $env(OPT)/$comp/$mpi/$name/$ver

prereq ecbuild
prereq netcdf
prereq eckit

prepend-path "PATH" $base/bin 
prepend-path "LD_LIBRARY_PATH" $base/lib
prepend-path "CPATH" $base/include
prepend-path "MANPATH" $base/share/man
prepend-path "PYTHONPATH" $base/lib/python2.7/site-packages

setenv "ODB_ROOT"  $base
setenv "ODB_API_PATH"  $base
setenv "ODB_API_VERSION" $ver

unset comp
unset mpi
unset name
unset ver
unset base
