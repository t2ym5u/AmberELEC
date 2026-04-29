# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2020-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="tgbdual"
PKG_VERSION="12540f0b2d3783259a0dce34ac8aa7a86beeaa11"
PKG_SHA256="2717509184ae532d147e1e8cc8009a49721cbdf6958af5d0f5d6875e7565f273"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/tgbdual-libretro"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="TGB Dual is an open source (GPLv2) GB/GBC emulator with game link cable support."
PKG_TOOLCHAIN="make"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp tgbdual_libretro.so ${INSTALL}/usr/lib/libretro/
}
