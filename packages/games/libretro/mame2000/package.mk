# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2020-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="mame2000"
PKG_VERSION="181b42e5da0d2f0c7a2e59244f23633ed594de2e"
PKG_SHA256="5420ee002c68afda1c54479ba1b80a4810705d7f4c18e5b6165bfd978968152e"
PKG_LICENSE="MAME"
PKG_SITE="https://github.com/libretro/mame2000-libretro"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="MAME - Multiple Arcade Machine Emulator"
PKG_TOOLCHAIN="make"

make_target() {
  make WANT_LIBCO=0
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp mame2000_libretro.so ${INSTALL}/usr/lib/libretro/
}