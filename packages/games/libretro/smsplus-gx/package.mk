# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2020-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="smsplus-gx"
PKG_VERSION="6dc7119f6f8d7f6437320405ee3b0de5f227913f"
PKG_SHA256="a25c3a816b77ac4542c8b448267bad9608cec804c88175cb21022cfd69b830ae"
PKG_LICENSE="Non-commercial"
PKG_SITE="https://github.com/libretro/smsplus-gx"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="SMS Plus is an open-source Sega Master System and Game Gear emulator written by Charles MacDonald."
PKG_TOOLCHAIN="make"

make_target() {
  if [ "${ARCH}" == "arm" ]; then
    CFLAGS="${CFLAGS} -DALIGN_LONG"
  fi
  make -f Makefile.libretro
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp smsplus_libretro.so ${INSTALL}/usr/lib/libretro/
}
