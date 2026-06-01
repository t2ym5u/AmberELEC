# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2022-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="prboom"
PKG_VERSION="5db4e55f8df3b9e53112b2444e8fd93dfce33304"
PKG_SHA256="b7ac0783038f808774701d75a904567133d53d4b21b4ed6fd7c73cb6ea76225c"
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
