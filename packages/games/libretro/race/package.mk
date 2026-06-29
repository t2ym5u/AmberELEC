# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2020-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="race"
PKG_VERSION="70a304213e1dc2e3474ee7ff5ee5137e5d285f33"
PKG_SHA256="261b6a3a951200d031fc830a1a11c3817f4388b0ef7189cbc5cd862c2b9a6099"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/RACE"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="This is the RACE NGPC emulator modified by theelf to run on the PSP."
PKG_TOOLCHAIN="make"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp race_libretro.so ${INSTALL}/usr/lib/libretro/
}