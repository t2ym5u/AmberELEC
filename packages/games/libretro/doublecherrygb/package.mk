# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2024-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="doublecherrygb"
PKG_VERSION="4721c00ab7c9a4ace50595a13f1212a1c29055cb"
PKG_SHA256="1eed873ec212fdca9638e7a018ffb84749a06fc6a6128c7a8e1eba54c8fcd415"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/TimOelrichs/doublecherryGB-libretro"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="libretro gameboy core with up to 16 players support"
PKG_TOOLCHAIN="make"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp DoubleCherryGB_libretro.so ${INSTALL}/usr/lib/libretro/
}