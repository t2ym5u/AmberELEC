# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2020-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="sameboy"
PKG_VERSION="c87d2565ea2eef1d342d0828c041ca71b5784aff"
PKG_LICENSE="MIT"
PKG_SITE="https://github.com/LIJI32/SameBoy"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Gameboy and Gameboy Color emulator written in C"
PKG_TOOLCHAIN="make"
PKG_GIT_CLONE_BRANCH="libretro"

make_target() {
  make -C libretro BOOTROMS_DIR=${PKG_BUILD}/BootROMs/prebuilt
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp ${PKG_BUILD}/sameboy_libretro.so ${INSTALL}/usr/lib/libretro/
}
