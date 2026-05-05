#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Validate BIOS files for AmberELEC.
# Usage: ./check_bios.sh [--bios-dir <path>] [--fix]
#
# --bios-dir <path>  Source folder containing your BIOS files (default: ./bios)
# --fix              Copy valid files to the target structure (dry-run without it)

set -euo pipefail

BIOS_DIR="$(cd "$(dirname "$0")" && pwd)/bios"
FIX=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bios-dir) BIOS_DIR="$2"; shift ;;
    --fix)      FIX=true ;;
    --help|-h)
      echo "Usage: $(basename "$0") [--bios-dir <path>] [--fix]"
      exit 0 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
  shift
done

[[ -d "$BIOS_DIR" ]] || { echo "ERROR: BIOS dir not found: $BIOS_DIR"; exit 1; }

# ── helpers ────────────────────────────────────────────────────────────────

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "  ${GREEN}✓${NC} $*"; }
miss() { echo -e "  ${RED}✗${NC} $*"; }
warn() { echo -e "  ${YELLOW}!${NC} $*"; }

FOUND=0; MISSING=0; BAD_CHECKSUM=0

md5_file() {
  if command -v md5sum >/dev/null 2>&1; then
    md5sum "$1" | cut -d' ' -f1
  else
    md5 -q "$1"
  fi
}

# check FILE SUBPATH [expected_md5]
#   FILE     = filename in bios/ (may include subfolder, e.g. dc/dc_boot.bin)
#   SUBPATH  = destination subpath on device (/storage/roms/bios/...)
#   md5      = optional expected MD5 (lowercase, no dashes)
check() {
  local file="$1" dest="$2" expected_md5="${3:-}"
  local src="${BIOS_DIR}/${file}"

  if [[ ! -f "$src" ]]; then
    miss "${file}  →  missing"
    (( MISSING++ )) || true
    return
  fi

  if [[ -n "$expected_md5" ]]; then
    local actual
    actual=$(md5_file "$src")
    if [[ "$actual" != "$expected_md5" ]]; then
      warn "${file}  →  BAD CHECKSUM (expected ${expected_md5}, got ${actual})"
      (( BAD_CHECKSUM++ )) || true
      return
    fi
  fi

  ok "${file}  →  ${dest}"
  (( FOUND++ )) || true
}

# ── BIOS manifest ──────────────────────────────────────────────────────────
# Format: check  <file in bios/>  <dest on device>  [md5]

echo ""
echo "AmberELEC BIOS check — $(date)"
echo "Source: $BIOS_DIR"
echo ""

echo "── Sega Saturn (Yabasanshiro) ─────────────────────────────────────────"
check  saturn_bios.bin   /storage/roms/bios/saturn_bios.bin  af5828fdff51384f99b3c4926be27762

echo ""
echo "── Sega Dreamcast (Flycast) ───────────────────────────────────────────"
check  dc/dc_boot.bin    /storage/roms/bios/dc/dc_boot.bin
check  dc/dc_flash.bin   /storage/roms/bios/dc/dc_flash.bin

echo ""
echo "── Atari ST (Hatari) ──────────────────────────────────────────────────"
check  tos.img           /storage/roms/bios/tos.img

echo ""
echo "── Atari 8-bit / 5200 (Atari800) ─────────────────────────────────────"
check  ATARIOSB.ROM      /storage/roms/bios/ATARIOSB.ROM
check  ATARIOSA.ROM      /storage/roms/bios/ATARIOSA.ROM
check  ATARIXL.ROM       /storage/roms/bios/ATARIXL.ROM
check  ATARIBAS.ROM      /storage/roms/bios/ATARIBAS.ROM
check  BASIC_Rev_A.rom   /storage/roms/bios/BASIC_Rev_A.rom
check  BASIC_Rev_B.rom   /storage/roms/bios/BASIC_Rev_B.rom
check  5200.rom          /storage/roms/bios/5200.rom
check  5200a.rom         /storage/roms/bios/5200a.rom

echo ""
echo "── Apple Pippin (PIEmu) ───────────────────────────────────────────────"
check  all.bin           /storage/roms/bios/all.bin

echo ""
echo "─────────────────────────────────────────────────────────────────────"
echo -e "  ${GREEN}Found${NC}: $FOUND   ${RED}Missing${NC}: $MISSING   ${YELLOW}Bad checksum${NC}: $BAD_CHECKSUM"
echo ""
