################################################################################
#
#  Copyright (C) 2021-present AmberELEC (https://github.com/AmberELEC)
#
#  This Program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2, or (at your option)
#  any later version.
#
#  This Program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU General Public License for more details.
#
################################################################################

PKG_NAME="gearcoleco"
PKG_VERSION="81b887893539ba12cde7a280fa9c802de7dd7176"
PKG_SHA256="8b956b5e5e1d482a0ac4c0d8ad764f4fcfc8af56d958fa5101498ac85dc8544a"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/drhelius/Gearcoleco"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Gearcoleco is a very accurate cross-platform ColecoVision emulator written in C++ that runs on Windows, macOS, Linux, BSD, Raspberry Pi and RetroArch."
PKG_TOOLCHAIN="make"

make_target() {
  make -C platforms/libretro/
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp platforms/libretro/gearcoleco_libretro.so ${INSTALL}/usr/lib/libretro/
}
