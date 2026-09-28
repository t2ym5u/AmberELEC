# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2021-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="freej2me"
PKG_VERSION="fae9304b85ac1c61d0117f6c8efe528612388278"
PKG_SHA256="4b67326eba243fd3d306fb4ce78c7e6d4d3776fa4eac74cd2da9a2b43a41e36a"
PKG_SITE="https://github.com/hex007/freej2me"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain apache-ant:host"
PKG_LONGDESC="A free J2ME emulator with libretro, awt and sdl2 frontends."
PKG_TOOLCHAIN="make"

pre_configure_target() {
  ${TOOLCHAIN}/bin/ant
}

make_target() {
  make -C ${PKG_BUILD}/src/libretro
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp ${PKG_BUILD}/src/libretro/freej2me_libretro.so ${INSTALL}/usr/lib/libretro/

  mkdir -p ${INSTALL}/usr/config/distribution/freej2me
  cp ${PKG_BUILD}/build/freej2me-lr.jar ${INSTALL}/usr/config/distribution/freej2me

  mkdir -p ${INSTALL}/usr/bin
  cp ${PKG_DIR}/freej2me.sh ${INSTALL}/usr/bin
}
