# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2021-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="wsdd2"
PKG_VERSION="1.9.2"
PKG_SHA256="4d1bec3c68fea57c072af49a7649781ece7280f809b18fc1576bb654b263b181"
PKG_LICENSE="GPL 3.0"
PKG_SITE="https://github.com/pesa1234/wsdd2"
PKG_URL="${PKG_SITE}/archive/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="WSD/LLMNR Discovery/Name Service Daemon"
PKG_BUILD_FLAGS="+size"

post_install() {
  enable_service wsdd2.service
}
