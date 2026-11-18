# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026-present AmberELEC (https://github.com/AmberELEC)

# Source only: ccache compiles xxhash.c into itself and nothing else uses it.
# This package exists so that scripts/get_archive fetches it, with retries and
# a mirror, rather than ccache's own FetchContent, which has neither. Same
# version and tarball as ccache 4.13 asks for.

PKG_NAME="xxhash"
PKG_VERSION="0.8.3"
PKG_SHA256="aae608dfe8213dfd05d909a57718ef82f30722c392344583d3f39050c7f29a80"
PKG_LICENSE="BSD"
PKG_SITE="https://xxhash.com"
PKG_URL="https://github.com/Cyan4973/xxHash/archive/refs/tags/v${PKG_VERSION}.tar.gz"
PKG_SOURCE_DIR="xxHash-${PKG_VERSION}"
PKG_LONGDESC="Extremely fast non-cryptographic hash algorithm (source for ccache)"
PKG_TOOLCHAIN="manual"
