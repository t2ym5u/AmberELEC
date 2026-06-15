# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2022-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="scummvm"
PKG_VERSION="8b8880c2de31adf7c5451fdad6a7e6826a7e8116"
PKG_SHA256="8e9782e9279f63ae5b35a11f25456e627f80da0f47bc2dd20ba0e278e84a0c6c"
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
