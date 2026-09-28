# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2025-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="freej2me-plus"
PKG_VERSION="7923b024b93bc24d6d227214e2ea99cb0e8c2234"
PKG_SHA256="ef3b500594c486159bc570b8ad9cd5a81aadb7c11a270cf3199c70a2c7a7a922"
PKG_SITE="https://github.com/TASEmulators/freej2me-plus"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain apache-ant:host"
PKG_LONGDESC="A free J2ME emulator with libretro, awt and sdl2 frontends."
PKG_TOOLCHAIN="make"

pre_configure_target() {
  sed -i 's/freej2me-lr.jar/freej2me-plus-lr.jar/g' ${PKG_BUILD}/build.xml
  sed -i 's/freej2me-lr\.jar/freej2me-plus-lr.jar/g' \
    ${PKG_BUILD}/src/libretro/freej2me_libretro.c \
    ${PKG_BUILD}/src/libretro/freej2me_libretro.h \
    ${PKG_BUILD}/src/libretro/freej2me_libretro.info

  ${TOOLCHAIN}/bin/ant
}

make_target() {
  make -C ${PKG_BUILD}/src/libretro
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp ${PKG_BUILD}/src/libretro/freej2me-plus_libretro.so ${INSTALL}/usr/lib/libretro/
  cp ${PKG_BUILD}/src/libretro/freej2me_libretro.info ${INSTALL}/usr/lib/libretro/freej2me-plus_libretro.info

  mkdir -p ${INSTALL}/usr/config/distribution/freej2me
  cp ${PKG_BUILD}/build/freej2me-plus-lr.jar ${INSTALL}/usr/config/distribution/freej2me

  mkdir -p ${INSTALL}/usr/bin
  cp ${PKG_DIR}/freej2me-plus.sh ${INSTALL}/usr/bin
}
