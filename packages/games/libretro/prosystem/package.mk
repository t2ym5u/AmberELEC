# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2022-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="prosystem"
PKG_VERSION="3f465db9c82fc6764cd90c53fc66eb630e0b3710"
PKG_SHA256="ae1ad456f11401b3294284217818814fad741c8f2fdd67f02e0baf33b6bf43ed"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/prosystem-libretro"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Port of ProSystem to libretro."
PKG_TOOLCHAIN="make"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp prosystem_libretro.so ${INSTALL}/usr/lib/libretro/
}
