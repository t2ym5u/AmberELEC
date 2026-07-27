# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2022-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="opera"
PKG_VERSION="0e9562eb2e2628fb4fc5d7180fd7125631da7fd4"
PKG_SHA256="ababea5824da784107b71df75274ab4ba49d25e9cd75dc22d0e6ec6c0d77d6a5"
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
