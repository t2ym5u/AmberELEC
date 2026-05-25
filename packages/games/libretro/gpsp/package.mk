# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2020-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="gpsp"
PKG_VERSION="d6decfa351b575e2936afebba26d41ec20e4ddcd"
PKG_SHA256="f489805f4f29ac8609b921c3254d57fd9030fefa2adae93b1433c448b939c8bb"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/gpsp"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="gameplaySP is a Gameboy Advance emulator for Playstation Portable"
PKG_TOOLCHAIN="make"

make_target() {
  if [ "${ARCH}" == "arm" ]; then
    make CC=${CC} platform=unix
  else
    make CC=${CC} platform=arm64
  fi  
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp gpsp_libretro.so ${INSTALL}/usr/lib/libretro/
}
