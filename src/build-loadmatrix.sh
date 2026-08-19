#!/bin/bash

set -euo pipefail

# absolute path with PWD so loadmatrix_geno works regardless of cwd
readonly HDF5_SRC=$PWD/hdf5-1.8.23
readonly HDF5_LIB=$HDF5_SRC/hdf5/lib
readonly HDF5_INCLUDE=$HDF5_SRC/hdf5/include

install-hdf5-1.8() {
  if [[ -f $HDF5_INCLUDE/hdf5.h && -f $HDF5_LIB/libhdf5.so ]]; then
    return
  fi

  curl -LO https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.23/src/hdf5-1.8.23.tar.gz
  tar -xzf hdf5-1.8.23.tar.gz

  (
    cd hdf5-1.8.23

    ## -Wincompatible-pointer-types was only a warning until GCC 14 made it an
    # error by default. This breaks compilation of HDF5 1.8.23 tools (h5diff,
    # h5dump, etc.)
    ./configure CFLAGS=-Wno-error=incompatible-pointer-types
    make
    make install
  )
}

build-loadmatrix() {
  # No need to check if loadmatrix_geno is already built, it builds quickly

  loadmatrix_cpp="$1"
  export LD_RUN_PATH=$HDF5_LIB

  g++ -Wno-narrowing -o loadmatrix_geno -I $HDF5_INCLUDE "$loadmatrix_cpp" -lhdf5 \
    -L $HDF5_LIB
}

install-hdf5-1.8
build-loadmatrix "$1"
