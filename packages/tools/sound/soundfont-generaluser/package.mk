# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2018-present 5schatten (https://github.com/5schatten)

PKG_NAME="soundfont-generaluser"
# GeneralUser GS 2.0.3, released 2026-02-22.
#
# 1.471 came from a Dropbox share that now answers every request with the
# "see this file" HTML page instead of the file - 198KB of text/html, and a
# different sha256 on each attempt, so the checksum retry loop could never
# converge. The LibreELEC mirror 404s as well, which left the package with no
# working source at all and failed the image stage.
#
# The author keeps the bank on GitHub and the README offers that repository
# as the source for automated packaging. It carries no tags, so the commit is
# the version, as it is for the other untagged GitHub packages here.
PKG_VERSION="684543d5e5efaef08d02be50dcda8d552478fa60"
PKG_SHA256="aef2e2901ab399061ac3765e259ab4c3409bdcb24b7cf814b4b54aaad549dbff"
PKG_LICENSE="OSS"
PKG_SITE="https://github.com/mrbumpy409/GeneralUser-GS"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET=""
PKG_LONGDESC="GeneralUser GS is a GM and GS compatible SoundFont bank for composing, playing MIDI files, and retro gaming."
PKG_TOOLCHAIN="manual"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/share/soundfonts
  # 2.0.1 dropped the version number from the filename, so this is no longer
  # a glob. The installed name stays GeneralUser.sf2: fluidsynth symlinks it
  # and timidity's config/GeneralUser.cfg names it, and neither tracks the
  # bank's version.
  cp GeneralUser-GS.sf2 ${INSTALL}/usr/share/soundfonts/GeneralUser.sf2
}
