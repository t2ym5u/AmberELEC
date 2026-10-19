# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="empty"
PKG_VERSION="0.6.23d"
PKG_SHA256="9ad495d52b942e3fd858643536d8d12e282568214300954d4518d8c22b893585"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/mezantrop/empty"
PKG_DEPENDS_TARGET="toolchain linux"
PKG_URL="http://downloads.sourceforge.net/sourceforge/${PKG_NAME}/${PKG_NAME}-${PKG_VERSION}.tgz"
PKG_SECTION="sysutils"
PKG_SHORTDESC="Run applications under pseudo-terminal sessions"
PKG_LONGDESC="Run applications under pseudo-terminal sessions"

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

make_target() {
  make CC=${CC}
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp empty ${INSTALL}/usr/bin/
}
