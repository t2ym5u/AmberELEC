# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2024-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="doublecherrygb"
PKG_VERSION="03f58ca3dfb4b716f7e66a0e0467f9e85ef82abb"
PKG_SHA256="48ef19f0c6e6bb7935a5282373c55f983cc307fb3192cb7d48bdcb7003dd5236"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/TimOelrichs/doublecherryGB-libretro"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="libretro gameboy core with up to 16 players support"
PKG_TOOLCHAIN="cmake"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp DoubleCherryGB_libretro.so ${INSTALL}/usr/lib/libretro/
}