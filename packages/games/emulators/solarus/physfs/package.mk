# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="physfs"
PKG_VERSION="ccffd00e1202a4fbd655f7c84171eee6182d9a53"
PKG_LICENSE="OSS"
PKG_SITE="https://github.com/icculus/physfs"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain glm"
PKG_LONGDESC="PhysicsFS; a portable, flexible file i/o abstraction."
PKG_TOOLCHAIN="cmake-make"

configure_target() {
 mkdir -p build
 cd build
 cmake ${PKG_BUILD}
}

make_target() {
  make
}

pre_makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib
  cp libphysfs.so* ${INSTALL}/usr/lib
}
