# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2020-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="gambatte"
PKG_VERSION="96174369b3c30d9fc57c926fa3379c273dc6a9a5"
PKG_SHA256="3da5df4d2c2bb1f56a4990c613d68300c0f311f5b29d146f79dc6ae3b2529380"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/gambatte-libretro"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Gambatte is an open-source Game Boy Color emulator written for fun and made available in the hope that it will be useful."
PKG_TOOLCHAIN="make"

if [[ "${DEVICE}" == RG351P ]] || [[ "${DEVICE}" == RG351V ]]; then
  PKG_PATCH_DIRS="rumble"
fi

make_target() {
  make -f Makefile.libretro
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp gambatte_libretro.so ${INSTALL}/usr/lib/libretro/
}
