# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2022-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="dosbox-pure"
PKG_VERSION="cdaea10ce8cac231bc341ca05d4c5e4e5fe0fbd5"
PKG_SHA256="c1c30bedc7254459d446047541570aad907252fdeb151daed2190ba64703ab97"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/dosbox-pure"
PKG_URL="https://github.com/libretro/dosbox-pure/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="A port of DOSBox to libretro"
PKG_TOOLCHAIN="make"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp dosbox_pure_libretro.so ${INSTALL}/usr/lib/libretro/
}
