# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2020-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="crocods"
PKG_VERSION="87bbb3d9007ac537864278c6c3149ae3291873f8"
PKG_SHA256="ff43a68ee74b36015a19c6083c03b1bca911603f824ed2b316ebdbc1898d8f7a"
PKG_LICENSE="MIT"
PKG_SITE="https://github.com/libretro/libretro-crocods"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Amstrad CPC emulator"
PKG_TOOLCHAIN="make"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp crocods_libretro.so ${INSTALL}/usr/lib/libretro/
}
