# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2020-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="race"
PKG_VERSION="2c543a671fd59d57be94ef5751922e6a55c98106"
PKG_SHA256="8d917f8adf8711dee9e966846786884065cf1ddc1a27824b94de0e54f4a6d899"
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