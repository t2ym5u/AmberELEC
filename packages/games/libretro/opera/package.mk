# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2022-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="opera"
PKG_VERSION="c95a315186aa963b095240d9cb34ea9da474ae8a"
PKG_SHA256="4360f45d03090fe45af09fbb34caef4f2768fb2dc8f447c08e97f4d751c6e57e"
PKG_LICENSE="LGPL with additional notes"
PKG_SITE="https://github.com/libretro/opera-libretro"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Port of 4DO/libfreedo to libretro."
PKG_TOOLCHAIN="make"

pre_configure_target() {
  sed -i 's/\-O[23]//' ${PKG_BUILD}/Makefile
}

make_target() {
  make CC=${CC} CXX=${CXX} AR=${AR}
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp opera_libretro.so ${INSTALL}/usr/lib/libretro/
}
