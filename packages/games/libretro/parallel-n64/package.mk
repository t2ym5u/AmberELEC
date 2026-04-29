# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)
# Copyright (C) 2021-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="parallel-n64"
PKG_VERSION="51aefbd38751563138b5fee3810ff653a78c4f24"
PKG_SHA256="e81e0c0fd37e4144cede4daa5fa66dadb0eb6ae048e2c9f98c27f5b67b08ae92"
PKG_REV="2"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/parallel-n64"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain ${OPENGLES}"
PKG_LONGDESC="Optimized/rewritten Nintendo 64 emulator made specifically for Libretro. Originally based on Mupen64 Plus."
PKG_TOOLCHAIN="make"

if [[ "${DEVICE}" =~ RG552 ]]; then
  PKG_MAKE_OPTS_TARGET=" platform=unix_RK3399"
else
  PKG_MAKE_OPTS_TARGET=" platform=unix_RK3326"
fi

if [[ "${DEVICE}" == RG351P ]] || [[ "${DEVICE}" == RG351V ]]; then
  PKG_PATCH_DIRS="rumble"
fi

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp parallel_n64_libretro.so ${INSTALL}/usr/lib/libretro/
}
