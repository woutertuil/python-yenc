### YENC ###
_build_yenc() {

local XPYTHON="${HOME}/xtools/python2/${DROBO}"
local BASE="${PWD}"
export QEMU_LD_PREFIX="${TOOLCHAIN}/${HOST}/libc"

git clone https://github.com/sabnzbd/sabyenc.git

pushd "sabyenc"
sed -e "s|from distutils.core import setup, Extension|from setuptools import setup\nfrom distutils.core import Extension|g" -i setup.py
PKG_CONFIG_PATH="${XPYTHON}/lib/pkgconfig" \
  LDFLAGS="${LDFLAGS:-} -Wl,-rpath,/mnt/DroboFS/Share/DroboApps/python2/lib -L${XPYTHON}/lib" \
  "${XPYTHON}/bin/python" setup.py \
    build_ext --include-dirs="${XPYTHON}/include" --library-dirs="${XPYTHON}/lib" --force \
    build --force \
    build_scripts --executable="/mnt/DroboFS/Share/DroboApps/python2/bin/python" --force \
    bdist_egg --dist-dir "${BASE}"
popd
}

### BUILD ###
_build() {
  _build_yenc
}

_clean() {
  rm -vfr *.egg
  rm -vfr "${DEPS}"
  rm -vfr "${DEST}"
  rm -vfr target/*
}
