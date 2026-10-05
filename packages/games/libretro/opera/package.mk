# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2022-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="opera"
PKG_VERSION="ea60917d7f8f79a19b46e1d8ecc6eca7be589b6a"
PKG_SHA256="db998563bc42aac474aa14cb2c96a052b8adf957f0ffaa8473e8ce7fe6319ed3"
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
