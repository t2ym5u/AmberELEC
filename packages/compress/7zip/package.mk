# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="7zip"
PKG_VERSION="26.05"
PKG_SHA256="989c658cef4c13124ed1f4ff7330a6ce5ab22cefdbbc9daae9b2c110dde9a63b"
PKG_LICENSE="LGPL-2.1+ (unRAR: restricted)"
PKG_SITE="https://github.com/ip7z/7zip"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_HOST="ccache:host"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="7-Zip is a file archiver with a high compression ratio. This is Igor Pavlov's own POSIX source, which replaces the p7zip port abandoned in 2016."
PKG_TOOLCHAIN="manual"

# 7-Zip selects its target through one of the CPP/7zip/cmpl_gcc*.mak wrappers,
# each of which only sets variables and then includes makefile.gcc.
#
# The host build deliberately uses the plain wrapper rather than the x64 one:
# var_gcc_x64.mak sets USE_ASM=1, and the x86 assembly wants asmc or uasm,
# which the build image does not have. The host binary only zips add-ons, so
# there is nothing to gain from it. The arm64 wrapper's USE_ASM is a different
# matter - that assembly is GNU as syntax and builds with our toolchain.
SEVENZIP_MAK_HOST="cmpl_gcc.mak"
sevenzip_mak_target() {
  case "${TARGET_ARCH}" in
    aarch64) echo "cmpl_gcc_arm64.mak" ;;
    *)       echo "cmpl_gcc.mak" ;;
  esac
}

# The host and the target pass share one unpacked tree, and each wrapper
# otherwise fixes its own output directory - b/g for the plain one,
# b/g_<platform> for the others - so a plain build would have the two passes
# landing in directories whose names depend on which wrapper was chosen.
# O is overridden on the command line instead, which make gives precedence
# over the wrapper's own assignment, and the makefile creates the directory
# itself (`all: $(O)`, MY_MKDIR=mkdir -p).
SEVENZIP_O_HOST="b/host"
SEVENZIP_O_TARGET="b/target"

# p7zip installed 7z, 7za and 7zr as three binaries supporting three different
# subsets of the formats. 7zz handles all of them, so one binary behind three
# names is a superset of what was there, and every caller keeps working
# untouched: runemu.py and sanity_check.py run /usr/bin/7z, MC's mc.ext and
# mc.menu run 7za on the device, scripts/install_addon runs
# ${TOOLCHAIN}/bin/7za and scripts/extract runs 7zr - that last one p7zip
# never actually installed on the host, so a .7z source would have failed.
sevenzip_links() {
  ln -sf 7zz "${1}/7z"
  ln -sf 7zz "${1}/7za"
  ln -sf 7zz "${1}/7zr"
}

make_host() {
  make -C "${PKG_BUILD}/CPP/7zip/Bundles/Alone2" \
       -f "../../${SEVENZIP_MAK_HOST}" \
       O="${SEVENZIP_O_HOST}"
}

makeinstall_host() {
  mkdir -p "${TOOLCHAIN}/bin"
  cp -p "${PKG_BUILD}/CPP/7zip/Bundles/Alone2/${SEVENZIP_O_HOST}/7zz" "${TOOLCHAIN}/bin/7zz"
  sevenzip_links "${TOOLCHAIN}/bin"
}

make_target() {
  # CROSS_COMPILE is the makefile's own hook - it builds CC and CXX as
  # $(CROSS_COMPILE)gcc and $(CROSS_COMPILE)g++, and TARGET_PREFIX is already
  # the full path form it expects.
  #
  # MY_ARCH is prepended to CFLAGS and defaults to -mtune=cortex-a53, which is
  # wrong for the three RK3326 devices; passing TARGET_CFLAGS replaces it with
  # the right -mcpu. The -O2 that follows in the makefile's own CFLAGS_BASE
  # wins over our -Ofast, which is what upstream tunes for anyway.
  #
  # CFLAGS_WARN_WALL is "-Werror -Wall -Wextra" upstream. -Werror belongs in
  # the author's own CI, not in a distribution build: it turns any warning
  # from a compiler upstream has not tested yet into a failed six-hour run.
  # 26.05 builds clean under gcc 14 with it on - this is for gcc 15.
  make -C "${PKG_BUILD}/CPP/7zip/Bundles/Alone2" \
       -f "../../$(sevenzip_mak_target)" \
       O="${SEVENZIP_O_TARGET}" \
       CROSS_COMPILE="${TARGET_PREFIX}" \
       MY_ARCH="${TARGET_CFLAGS}" \
       CFLAGS_WARN_WALL="-Wall -Wextra"
}

makeinstall_target() {
  mkdir -p "${INSTALL}/usr/bin"
  cp -p "${PKG_BUILD}/CPP/7zip/Bundles/Alone2/${SEVENZIP_O_TARGET}/7zz" "${INSTALL}/usr/bin/7zz"
  sevenzip_links "${INSTALL}/usr/bin"
}
