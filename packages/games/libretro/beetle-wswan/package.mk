# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2020-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="beetle-wswan"
PKG_VERSION="da6d0d9acb8d4e9bd6725ab44225a275325d8352"
PKG_SHA256="420fab5729fa0f55bb97683021ea69c8b1e7e7ecf1a946213cd58c90d3effc2a"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/beetle-wswan-libretro"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="libretro implementation of Mednafen wswan"
PKG_TOOLCHAIN="make"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp mednafen_wswan_libretro.so ${INSTALL}/usr/lib/libretro/beetle_wswan_libretro.so
}
