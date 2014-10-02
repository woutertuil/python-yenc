#!/usr/bin/env bash

### bash best practices ###
# exit on error code
set -o errexit
# exit on unset variable
set -o nounset
# return error of last failed command in pipe
set -o pipefail
# expand aliases
shopt -s expand_aliases
# print trace
set -o xtrace

### logfile ###
timestamp="$(date +%Y-%m-%d_%H-%M-%S)"
logfile="logfile_${timestamp}.txt"
echo "${0} ${@}" > "${logfile}"
# save stdout to logfile
exec 1> >(tee -a "${logfile}")
# redirect errors to stdout
exec 2> >(tee -a "${logfile}" >&2)

### environment variables ###
source crosscompile.sh
export NAME="pyopenssl"
export DEST="/mnt/DroboFS/Shares/DroboApps/python2"
export DEPS="${PWD}/target/install"
export CFLAGS="$CFLAGS -Os -fPIC -ffunction-sections -fdata-sections"
export CXXFLAGS="$CXXFLAGS $CFLAGS"
export LDFLAGS="${LDFLAGS:-} -Wl,-rpath,${DEST}/lib"
alias make="make -j8 V=1 VERBOSE=1"

# $1: file
# $2: url
# $3: folder
_download_tgz() {
  [[ ! -f "download/${1}" ]] && wget -O "download/${1}" "${2}"
  [[ -d "target/${3}" ]]   && rm -v -fr "target/${3}"
  [[ ! -d "target/${3}" ]] && tar -zxvf "download/${1}" -C target
}

### YENC ###
_build_yenc() {
local VERSION="0.4.0"
local FOLDER="yenc-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://www.golug.it/pub/yenc/${FILE}"
local XPYTHON=~/xtools/python2/${DROBO}

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
sed -i -e "s|from distutils.core import setup, Extension|from setuptools import setup\nfrom distutils.core import Extension|g" setup.py
_PYTHON_HOST_PLATFORM="linux-armv7l" LDSHARED="${CC} -shared -Wl,-rpath,/mnt/DroboFS/Share/DroboApps/python2/lib -L${DEST}/lib-5n" "${XPYTHON}/bin/python" setup.py build_ext --include-dirs="${XPYTHON}/include-${DROBO}" --library-dirs="${XPYTHON}/lib-${DROBO}" --force build --force bdist_egg --dist-dir ../..
popd
}

### BUILD ###
_build() {
  _build_yenc
}

_clean() {
  rm -v -fr *.egg
  rm -v -fr target/*
}

_dist_clean() {
  _clean
  rm -v -f logfile*
  rm -v -fr download/*
}

case "${1:-}" in
  clean)     _clean ;;
  distclean) _dist_clean ;;
  "")        _build ;;
  *)         _build_${1} ;;
esac
