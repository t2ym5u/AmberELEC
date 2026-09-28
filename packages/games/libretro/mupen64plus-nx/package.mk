# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Fewtarius

PKG_NAME="mupen64plus-nx"
PKG_VERSION="6752836de8b224febfd5708444755b77712ac939"
PKG_SHA256="78509e9787729aa0051915e646200ce21ab2d7e809318c9b1dfdaabcab2f067d"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/mupen64plus-libretro-nx"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain nasm:host ${OPENGLES}"
PKG_LONGDESC="mupen64plus NX"
PKG_TOOLCHAIN="make"

pre_configure_target() {
  sed -e "s|^GIT_VERSION ?.*$|GIT_VERSION := \" ${PKG_VERSION:0:7}\"|" -i Makefile
}

make_target() {
  cd ${PKG_BUILD}
  local platform="RK3326"
  [ "${DEVICE}" = "RG552" ] && platform="RK3399"

  make platform="${platform}" HAVE_PARALLEL_RSP=1
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp ${PKG_BUILD}/mupen64plus_next_libretro.so ${INSTALL}/usr/lib/libretro/
}
