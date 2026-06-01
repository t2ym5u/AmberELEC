# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2022-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="core-info"
PKG_VERSION="f8b241d098e74c668001bb0aba8129b40afe7d03"
PKG_SHA256="3436c9218fb6935dfa3c4153989f2fcc7510ab56934baca636c6eb2c8d577ccd"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/libretro/libretro-core-info"
PKG_URL="https://github.com/libretro/libretro-core-info/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain util-linux:host"
PKG_LONGDESC="Mirror of libretro's core info files"
PKG_TOOLCHAIN="manual"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  ${TOOLCHAIN}/bin/rename -v mednafen beetle ${PKG_BUILD}/*.info
  cp ${PKG_BUILD}/*.info ${INSTALL}/usr/lib/libretro/
  cp ${PKG_BUILD}/flycast_libretro.info ${INSTALL}/usr/lib/libretro/flycast2021_libretro.info
  sed -i 's/Flycast/Flycast 2021/g' ${INSTALL}/usr/lib/libretro/flycast2021_libretro.info 
}
