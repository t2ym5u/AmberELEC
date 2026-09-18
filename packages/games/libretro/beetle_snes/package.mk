# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2023-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="beetle_snes"
PKG_VERSION="5f05e4c785e936c928ac468e129c55b6f08592cb"
PKG_SHA256="7b2ffad2c1abf0c90867ecb707dc91486f4c787c535ae406c343eb429a15c136"
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
