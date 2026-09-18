# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2022-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="nestopia"
PKG_VERSION="224713b257c8620513c1c9ca28dc7f8dea711e18"
PKG_SHA256="48f32948ade239d4e912a4b993f6e70f2cd8f4471194275fc376f15a073397ef"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/nestopia"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="This project is a fork of the original Nestopia source code, plus the Linux port. The purpose of the project is to enhance the original, and ensure it continues to work on modern operating systems."
PKG_TOOLCHAIN="make"

make_target() {
  cd ${PKG_BUILD}
  make -C libretro
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp libretro/nestopia_libretro.so ${INSTALL}/usr/lib/libretro/
}
