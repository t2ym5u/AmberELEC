# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2020-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="beetle-pce-fast"
PKG_VERSION="3f946f277aef3aa99a95551618bbcd1dd2bda0d9"
PKG_SHA256="1bc1d96f2a0957e97d50c009d25ae5725d60e80eada679dafbb214afa84cda29"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/beetle-pce-fast-libretro"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Standalone port of Mednafen PCE Fast to libretro."
PKG_TOOLCHAIN="make"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp mednafen_pce_fast_libretro.so ${INSTALL}/usr/lib/libretro/beetle_pce_fast_libretro.so
}
