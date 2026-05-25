# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2022-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="prboom"
PKG_VERSION="648223372e24773821a2041e0c39728f723badf4"
PKG_SHA256="3c3f4ab0d1165318f6f7d1d81272c7d87696c403e5d9a48cd929de7e84aa3866"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/libretro-prboom"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="libretro implementation of Doom"
PKG_TOOLCHAIN="make"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp prboom_libretro.so ${INSTALL}/usr/lib/libretro/prboom_libretro.so
}
