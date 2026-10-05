# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2022-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="scummvm"
PKG_VERSION="8e5d6896e7ba8bc46c2c6c5ac5a0a526ab27371d"
PKG_SHA256="c9feeddd5de360ca58cea273392e5b826296363307107cb89961e21e13312c0c"
PKG_LICENSE="GPL2"
PKG_SITE="https://github.com/scummvm/scummvm"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="ScummVM is a program which allows you to run certain classic graphical point-and-click adventure games, provided you already have their data files."

configure_target() {
  :
}

make_target() {
  cd ${PKG_BUILD}/backends/platform/libretro
  make all
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp scummvm_libretro.so ${INSTALL}/usr/lib/libretro/
  mkdir -p ${INSTALL}/usr/share/scummvm
  unzip scummvm.zip -d ${INSTALL}/usr/share/
}
