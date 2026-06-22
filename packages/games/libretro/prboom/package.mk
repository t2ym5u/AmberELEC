# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2022-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="prboom"
PKG_VERSION="b760de6a1eb1bfcd7833c5b677ff9170d104302f"
PKG_SHA256="b5acc367942ccd71771abab376ffd5c54ed4cc9fe40ecbb89371cec197f0747a"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/libretro-prboom"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="libretro implementation of Doom"
PKG_TOOLCHAIN="make"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp prboom_libretro.so ${INSTALL}/usr/lib/libretro/prboom_libretro.so
}
