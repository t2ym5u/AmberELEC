# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2020-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="cap32"
PKG_VERSION="2d41a1f07e654e97c4f24ab8447c3fbd7d728bc8"
PKG_SHA256="c2274c6f2e3e7a1b0e8ad824083ea506f92bcb30a18a04da23dcb00d3367e9ea"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/libretro-cap32"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="caprice32 4.2.0 libretro"
PKG_TOOLCHAIN="make"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp cap32_libretro.so ${INSTALL}/usr/lib/libretro/
}
