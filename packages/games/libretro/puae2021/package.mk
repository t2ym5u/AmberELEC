# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2022-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="puae2021"
PKG_VERSION="65379fa6abbad8fb3f21a004f48421967cc505d3"
PKG_SHA256="0417e1aca7eeed151ad9c0fcbc2733d4ac254e1d224568cc058dbb8fb0964cb6"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/libretro/libretro-uae"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="WIP libretro port of UAE (P-UAE and libco) Expect bugs"
PKG_TOOLCHAIN="make"
PKG_GIT_CLONE_BRANCH="2.6.1"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp puae2021_libretro.so ${INSTALL}/usr/lib/libretro/
}
