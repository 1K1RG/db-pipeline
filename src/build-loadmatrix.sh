#!/bin/bash

install-hdf5-1.8() {
  curl -LO https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.23/src/hdf5-1.8.23.tar.gz
  tar -xzf hdf5-1.8.23.tar.gz
  cd hdf5-1.8.23

  ## -Wincompatible-pointer-types was only a warning until GCC 14 made it an
  # error by default. This breaks compilation of HDF5 1.8.23 tools (h5diff,
  # h5dump, etc.)
  ./configure CFLAGS=-Wno-error=incompatible-pointer-types
  make
  make install

  cd ..
}

build-loadmatrix() {
  loadmatrix_cpp="$1"

  main=$PWD/hdf5-1.8.23
  lib=$main/hdf5/lib
  include=$main/hdf5/include
  header=$include

  export PATH=$main/hdf5/bin:$PATH
  export LD_RUN_PATH=$lib
  export LDFLAGS="-L$lib"
  export CPPFLAGS="-I$include"

  g++ -Wno-narrowing -o loadmatrix_geno -I $header "$loadmatrix_cpp" -lhdf5 -L$lib
}

install-hdf5-1.8
build-loadmatrix "$1"
