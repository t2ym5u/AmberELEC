# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="x264"
PKG_VERSION="baee400fa9ced6f5481a728138fed6e867b0ff7f" # r3095 stable 2022-06-01
PKG_LICENSE="GPL"
PKG_SITE="http://www.videolan.org/developers/x264.html"
# Cloned rather than fetched as an archive: code.videolan.org is unreachable,
# and a GitLab/GitHub auto-generated tarball is regenerated on demand, so
# pinning a checksum against one invites the break dav1d and squashfs-tools
# both hit. The commit hash is its own integrity check.
PKG_URL="https://github.com/mirror/x264.git"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="x264 codec"

if [ "${TARGET_ARCH}" = "x86_64" ]; then
  PKG_DEPENDS_TARGET+=" nasm:host"
fi

pre_configure_target() {
  cd ${PKG_BUILD}
  rm -rf .${TARGET_NAME}

  if [ "${TARGET_ARCH}" = "x86_64" ]; then
    export AS="${TOOLCHAIN}/bin/nasm"
  else
    PKG_X264_ASM="--disable-asm"
  fi
}

configure_target() {
  ./configure \
    --cross-prefix="${TARGET_PREFIX}" \
    --extra-cflags="${CFLAGS}" \
    --extra-ldflags="${LDFLAGS}" \
    --host="${TARGET_NAME}" \
    --prefix="/usr" \
    --sysroot="${SYSROOT_PREFIX}" \
    ${PKG_X264_ASM} \
    --disable-cli \
    --enable-lto \
    --enable-shared \
    --enable-pic \
    --enable-strip
}
