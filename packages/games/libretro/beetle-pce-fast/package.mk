# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2020-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="beetle-pce-fast"
PKG_VERSION="b211204c7026dff6e86e79b00185512e2421fff8"
PKG_SHA256="ec3ef1874f0590ab6d5cd4bba86969ee085e8bef2de4b4e5f2422fe38a2c2d3d"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/beetle-pce-fast-libretro"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Standalone port of Mednafen PCE Fast to libretro."
PKG_TOOLCHAIN="make"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp mednafen_pce_fast_libretro.so ${INSTALL}/usr/lib/libretro/beetle_pce_fast_libretro.so
}
