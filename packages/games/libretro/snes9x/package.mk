# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2022-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="snes9x"
PKG_VERSION="fae2fea08f74180759ef540ee94259213f503480"
PKG_SHA256="0d4b0c4181d66668ec0040eb17f90a559f7b7fa6cbd9198593c3bdbe79acd029"
PKG_LICENSE="Non-commercial"
PKG_SITE="https://github.com/libretro/snes9x"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Snes9x - Portable Super Nintendo Entertainment System (TM) emulator"
PKG_TOOLCHAIN="make"

make_target() {
  if [ "${ARCH}" == "arm" ]; then
    CXXFLAGS="${CXXFLAGS} -DARM"
  fi
  
  make -C libretro
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp libretro/snes9x_libretro.so ${INSTALL}/usr/lib/libretro/
}
