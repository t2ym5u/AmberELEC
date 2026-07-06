# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)
# Copyright (C) 2021-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="parallel-n64"
PKG_VERSION="ad3abdacf1e7ba9014e5b018f3e8ea6484399189"
PKG_SHA256="29f35222d734af5623845b31bae6c2eb2e31180b804608ecd84c7a41c1192bd4"
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
