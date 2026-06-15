# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2020-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="gpsp"
PKG_VERSION="2db57b11a437c4432ab69823bdcd951181de6213"
PKG_SHA256="27a5487ad3d6323a953b2e78db271467618e5038b4cfce77bec71be17d2b22e5"
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
