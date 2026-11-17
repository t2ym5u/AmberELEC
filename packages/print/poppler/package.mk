# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)
# Copyright (C) 2022-present AmberELEC (https://github.com/AmberELEC

PKG_NAME="poppler"
PKG_VERSION="26.08.0"
PKG_LICENSE="GPL"
PKG_SITE="https://poppler.freedesktop.org/"
PKG_URL="${PKG_SITE}poppler-${PKG_VERSION}.tar.xz"
# No boost: poppler 26.08 wants 1.83 or later and ours is 1.82. It only
# speeds up the Splash backend; turn ENABLE_BOOST back on once boost moves on.
PKG_DEPENDS_TARGET="toolchain zlib libpng libjpeg-turbo tiff fontconfig curl"
PKG_LONGDESC="The poppler pdf rendering library "
PKG_TOOLCHAIN="cmake-make"

PKG_CMAKE_OPTS_TARGET="-DCMAKE_BUILD_TYPE=release \
                       -DENABLE_GLIB=ON \
                       -DENABLE_QT5=OFF \
                       -DENABLE_QT6=OFF \
                       -DENABLE_NSS3=OFF \
                       -DENABLE_LCMS=OFF \
                       -DENABLE_GPGME=OFF \
                       -DENABLE_LIBOPENJPEG=OFF \
                       -DENABLE_CPP=OFF \
                       -DENABLE_BOOST=OFF"
