# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2020-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="beetle-vb"
PKG_VERSION="7cc663e9044459b3dab1790bdce8f48dc7358ed6"
PKG_SHA256="1affe22511f928fbe6982e8512e44042e71d9a74f0a302140544090f9b9bb41d"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/beetle-vb-libretro"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="libretro implementation of Mednafen VB. (VirtualBoy)"
PKG_TOOLCHAIN="make"

pre_configure_target() {
  sed -i 's/\-O[23]//' ${PKG_BUILD}/Makefile
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp mednafen_vb_libretro.so ${INSTALL}/usr/lib/libretro/beetle_vb_libretro.so
}
