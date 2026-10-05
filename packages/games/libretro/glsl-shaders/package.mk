# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2020-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="glsl-shaders"
PKG_VERSION="435612fe4f1023117b3aae48c88603fb413404a3"
PKG_SHA256="16e89c0028d700e0475cb415c2ec5cc36b6319ca8454952db5bf6bcdafb25ec7"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/libretro/glsl-shaders"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain common-shaders"
PKG_LONGDESC="Common GSLS shaders for RetroArch"
PKG_TOOLCHAIN="make"

configure_target() {
  cd ${PKG_BUILD}
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/share/common-shaders
  cp -rf * ${INSTALL}/usr/share/common-shaders/
  cp -rf ${PKG_DIR}/shaders/* ${INSTALL}/usr/share/common-shaders/
}

post_makeinstall_target() {
  cp -f ${PKG_DIR}/removeshaders.sh .
  chmod 755 removeshaders.sh
  /bin/sh removeshaders.sh ${INSTALL}
}
