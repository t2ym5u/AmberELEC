# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2020-present AmberELEC (https://github.com/AmberELEC)

### Don't update, newer commits have issues.
PKG_NAME="common-shaders"
PKG_VERSION="43eaf9b91857eb8515310c74ae750895d77b20f8"
PKG_SHA256="4bc1bc61604e91fe314cf781d05b3b99e1991e65a6adafcb8464e633e156a58e"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/RetroPie/common-shaders"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_SECTION="emuelec"
PKG_LONGDESC="Manually converted libretro/common-shaders for arm devices treebranch pi"
PKG_GIT_CLONE_BRANCH="rpi"
PKG_TOOLCHAIN="make"

make_target() {
  : not
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/share/common-shaders/rpi
  cp -rf ${BUILD}/${PKG_NAME}-${PKG_VERSION}/* ${INSTALL}/usr/share/common-shaders/rpi
}

