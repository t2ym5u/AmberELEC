# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2020-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="beetle-gba"
PKG_VERSION="b158166237b17253188cfdbe73a8a0b9fe4b3a8c"
PKG_SHA256="9633e42ca3fb4acd3f9d6d3b6e9ca24765df0a863f688bb84fac4b767587f5da"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/beetle-gba-libretro"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="libretro implementation of Mednafen VBA/GBA. (Game Boy Advance)"
PKG_TOOLCHAIN="make"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp mednafen_gba_libretro.so ${INSTALL}/usr/lib/libretro/beetle_gba_libretro.so
}
