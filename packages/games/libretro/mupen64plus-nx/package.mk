# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Fewtarius

PKG_NAME="mupen64plus-nx"
PKG_VERSION="98c1b0d877542b01314b3b04272282ba223b65b3"
PKG_SHA256="3843919d459724d8b0d78e4a819b43a7ef1847dd9bae4bb41e0fd5e8bd72567d"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/mupen64plus-libretro-nx"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain nasm:host ${OPENGLES}"
PKG_LONGDESC="mupen64plus NX"
PKG_TOOLCHAIN="make"

pre_configure_target() {
  sed -e "s|^GIT_VERSION ?.*$|GIT_VERSION := \" ${PKG_VERSION:0:7}\"|" -i Makefile

  if [ "${DEVICE}" = "RG552" ]; then
    PKG_MAKE_OPTS_TARGET+=" platform=RK3399 HAVE_PARALLEL_RSP=1"
  else
    PKG_MAKE_OPTS_TARGET+=" platform=RK3326 HAVE_PARALLEL_RSP=1"
  fi
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp mupen64plus_next_libretro.so ${INSTALL}/usr/lib/libretro/
}
