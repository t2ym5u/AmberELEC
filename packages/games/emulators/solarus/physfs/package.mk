# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="physfs"
PKG_VERSION="cfd3f4e6ca70b2c080a68f5e8a7427369ea2553b"
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
