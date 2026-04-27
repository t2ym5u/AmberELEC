# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2023-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="beetle_snes"
PKG_VERSION="e2b7694d12c44a2842cf4640844287f622026d9a"
PKG_SHA256="f3debec219fefd43077f3b66d9dd194720722ee2fea20e9bc315ccbd92291b64"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/beetle-bsnes-libretro"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Standalone port of Mednafen bSNES to libretro, itself a fork of bsnes 0.59."
PKG_TOOLCHAIN="make"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp mednafen_snes_libretro.so ${INSTALL}/usr/lib/libretro/beetle_snes_libretro.so
}
