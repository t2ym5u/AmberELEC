# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2020-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="fceumm"
PKG_VERSION="3a84a6fd0ba20dd4877c06b1d58741172148395f"
PKG_SHA256="bdac7fec58089d8bcbe3f8ab7cf7da049f23ac53cb8fc7dabc8e13e075f1c004"
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
