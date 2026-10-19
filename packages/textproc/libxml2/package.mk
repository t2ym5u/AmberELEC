# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libxml2"
PKG_VERSION="2.9.10"
PKG_SHA256="593b7b751dd18c2d6abcd0c4bcb29efc203d0b4373a6df98e3a455ea74ae2813"
#PKG_SHA256=""
PKG_LICENSE="MIT"
PKG_SITE="http://xmlsoft.org"
PKG_URL="https://download.gnome.org/sources/libxml2/2.9/${PKG_NAME}-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_HOST="zlib:host"
PKG_DEPENDS_TARGET="toolchain zlib"
PKG_LONGDESC="The libxml package contains an XML library, which allows you to manipulate XML files."

PKG_CONFIGURE_OPTS_ALL="ac_cv_header_ansidecl_h=no \
             --enable-static \
             --enable-shared \
             --disable-silent-rules \
             --enable-ipv6 \
             --without-python \
             --with-zlib=${TOOLCHAIN} \
             --without-lzma"

PKG_CONFIGURE_OPTS_HOST="${PKG_CONFIGURE_OPTS_ALL} --with-zlib=${TOOLCHAIN}"

PKG_CONFIGURE_OPTS_TARGET="${PKG_CONFIGURE_OPTS_ALL} --with-zlib=${SYSROOT_PREFIX}/usr --with-sysroot=${SYSROOT_PREFIX}"

post_makeinstall_target() {
  sed -e "s:\(['= ]\)/usr:\\1${SYSROOT_PREFIX}/usr:g" -i ${SYSROOT_PREFIX}/usr/bin/xml2-config

  rm -rf ${INSTALL}/usr/bin/xml2-config
  rm -rf ${INSTALL}/usr/lib/xml2Conf.sh
}
