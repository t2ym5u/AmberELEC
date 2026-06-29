# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2020-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="vba-next"
PKG_VERSION="349b57c6442af56248433c114500a460ef9bfd8c"
PKG_SHA256="62123ef937b38b0190475d6a8c389f8f176e86405ce4cd3e3b9c0eb59d1f1252"
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
