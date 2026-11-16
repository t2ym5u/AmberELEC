# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019 Trond Haugland (trondah@gmail.com)
# Copyright (C) 2022-present AmberELEC (https://github.com/AmberELEC)

# mame is not compiled here. From scratch it takes nine hours or more, longer
# than a hosted CI job, and its objects do not fit in the compiler cache next
# to the other packages. t2ym5u/amberelec-mame holds the source recipe that
# used to live here, builds it with this tree's toolchain and publishes the
# core; this package installs that.
#
# The binary is linked against libraries of this image. Rebuild it there, then
# update PKG_VERSION and the PKG_SHA256 below, whenever gcc (libstdc++), glibc,
# zlib, flac, sqlite, expat, alsa-lib or mame itself change.

PKG_NAME="mame"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/t2ym5u/amberelec-mame"
# The runtime libraries the core links against.
PKG_DEPENDS_TARGET="toolchain zlib flac sqlite expat alsa-lib"
PKG_LONGDESC="MAME - Multiple Arcade Machine Emulator (prebuilt libretro core)"
PKG_TOOLCHAIN="manual"

case "${DEVICE}" in
  RG351P|RG351V|RG351MP)
    PKG_VERSION="eb342748c828-rk3326-amberelec-f6c36f49"
    PKG_SHA256="6b2aed1997c5c527241b2932097eb8ddb580ed770616542e9d3dcc2fb209d2d6"
    ;;
  *)
    die "mame: no prebuilt core for ${DEVICE} yet - run build-mame in t2ym5u/amberelec-mame for it"
    ;;
esac
PKG_URL="${PKG_SITE}/releases/download/${PKG_VERSION}/mame_libretro-${PKG_VERSION}.tar.xz"

# The archive holds its two files at the top, with no directory around them.
unpack() {
  mkdir -p ${PKG_BUILD}
  tar -xJf ${SOURCES}/${PKG_NAME}/${PKG_SOURCE_NAME} -C ${PKG_BUILD}
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp ${PKG_BUILD}/mame_libretro.so ${INSTALL}/usr/lib/libretro/mame_libretro.so
  mkdir -p ${INSTALL}/usr/config/retroarch/savefiles/mame/hi
  cp -f ${PKG_BUILD}/hiscore.dat ${INSTALL}/usr/config/retroarch/savefiles/mame/hi
  mkdir -p ${INSTALL}/usr/config/mame
  cp ${PKG_DIR}/config/*.cfg ${INSTALL}/usr/config/mame
}
