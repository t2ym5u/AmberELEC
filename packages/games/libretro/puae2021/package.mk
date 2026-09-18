# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2022-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="puae2021"
PKG_VERSION="297b34777372fd5f117785798f99b4c7433b6034"
PKG_SHA256="53a6e7f49e479af4c5f6e35dfef8ad7fc5ea95231440024bcc4f085375683d08"
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
