# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2020-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="vba-next"
PKG_VERSION="788192f215ad0a1413f1625b40ebba3423fa0ade"
PKG_SHA256="e97c5839474183ba4b05db212b6c7b09ef7e0bfba3a2cab2ed8ebe34abe8339d"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/libretro/vba-next"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Optimized port of VBA-M to Libretro. "
PKG_TOOLCHAIN="make"

make_target() {
  make -f Makefile.libretro
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp vba_next_libretro.so ${INSTALL}/usr/lib/libretro/
}
