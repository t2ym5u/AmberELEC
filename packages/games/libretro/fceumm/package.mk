# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2020-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="fceumm"
PKG_VERSION="47248b374b913b5af7a433d2dbdbc35a869048a6"
PKG_SHA256="cd5406decdd814985ad22d2cad19781abb934ed33541712fa7a42f018f1800c8"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/libretro-fceumm"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="FCEUX is a Nintendo Entertainment System (NES), Famicom, and Famicom Disk System (FDS) emulator."
PKG_TOOLCHAIN="make"

pre_configure_target() {
  sed -i 's/\-O[23]//' ${PKG_BUILD}/Makefile.libretro
}

make_target() {
  make -f Makefile.libretro
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp fceumm_libretro.so ${INSTALL}/usr/lib/libretro/
}
