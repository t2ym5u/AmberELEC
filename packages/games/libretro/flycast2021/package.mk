# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2021-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="flycast2021"
PKG_VERSION="45bd2f4e59708a7c16a5bb1cb90a94d1b39e330d"
PKG_SHA256="83434fa00b02f0188ec9225ee3a9c2133f7fcd3a323f00d160ff8f8f9aca4bae"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/parallel-dc"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain ${OPENGLES}"
PKG_LONGDESC="Flycast is a multiplatform Sega Dreamcast emulator"
PKG_TOOLCHAIN="make"

pre_configure_target() {
  sed -i 's/\-O[23]//' ${PKG_BUILD}/Makefile
  sed -i 's/CFLAGS   :=//' ${PKG_BUILD}/Makefile
  sed -i 's/CXXFLAGS   :=//' ${PKG_BUILD}/Makefile
  sed -i 's/LDFLAGS   :=//' ${PKG_BUILD}/Makefile
  sed -i 's/define CORE_OPTION_NAME "reicast"/define CORE_OPTION_NAME "flycast2021"/g' core/libretro/libretro_core_option_defines.h
  sed -i 's/"Flycast"/"Flycast 2021"/g' core/libretro/libretro.cpp
  sed -i 's/RETRO_PIXEL_FORMAT_XRGB8888/RETRO_PIXEL_FORMAT_RGB565/g' core/libretro/libretro.cpp
  export CFLAGS="${CFLAGS} -Wno-error=implicit-function-declaration"
}

make_target() {
  local my_cc="${CC}"
  local my_cxx="${CXX}"

  if [ -n "${CCACHE_DIR}" ] && [ -x "${TOOLCHAIN}/bin/ccache" ]; then
    my_cc="${TOOLCHAIN}/bin/ccache ${CC}"
    my_cxx="${TOOLCHAIN}/bin/ccache ${CXX}"
  fi

  export BUILD_SYSROOT="${SYSROOT_PREFIX}"

  make ARCH=arm \
       platform=arm64 \
       GIT_VERSION="${PKG_VERSION:0:7}" \
       CC="${my_cc}" \
       CXX="${my_cxx}" \
       SHARED="-shared" \
       LDFLAGS="${LDFLAGS}" \
       ${MAKEFLAGS}
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp flycast_libretro.so ${INSTALL}/usr/lib/libretro/flycast2021_libretro.so
}
