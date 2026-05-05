#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Déploie les BIOS depuis bios/ vers la carte SD AmberELEC.
#
# Usage:
#   ./deploy_bios.sh                        # détection auto du volume
#   ./deploy_bios.sh /Volumes/GAMES         # volume explicite
#   ./deploy_bios.sh --dry-run              # simulation sans copie

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BIOS_SRC="${SCRIPT_DIR}/bios"
DRY_RUN=false
TARGET=""

# ── options ────────────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true ;;
    --help|-h)
      echo "Usage: $(basename "$0") [/Volumes/<SD>] [--dry-run]"
      exit 0 ;;
    /*) TARGET="$1" ;;
    *) echo "Option inconnue : $1"; exit 1 ;;
  esac
  shift
done

# ── détection auto du volume ───────────────────────────────────────────────

if [[ -z "$TARGET" ]]; then
  # Cherche un volume monté qui ressemble à une carte SD AmberELEC
  for vol in /Volumes/GAMES /Volumes/ROMS /Volumes/BATOCERA /Volumes/AMBERELEC /Volumes/storage; do
    if [[ -d "$vol" ]]; then
      TARGET="$vol"
      break
    fi
  done

  if [[ -z "$TARGET" ]]; then
    echo "Aucun volume AmberELEC détecté automatiquement."
    echo "Volumes disponibles :"
    ls /Volumes/
    echo ""
    echo "Relance avec : $(basename "$0") /Volumes/<NOM>"
    exit 1
  fi
fi

BIOS_DEST="${TARGET}/bios"

echo ""
echo "Source  : $BIOS_SRC"
echo "Cible   : $BIOS_DEST"
$DRY_RUN && echo "(mode simulation — aucun fichier ne sera copié)"
echo ""

# ── helpers ────────────────────────────────────────────────────────────────

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
COPIED=0; SKIPPED=0

deploy() {
  local src="$1" dest_dir="$2" dest_name="${3:-}"
  local src_path="${BIOS_SRC}/${src}"
  local dest_file

  [[ -f "$src_path" ]] || { echo "  - manquant : $src"; return; }

  if [[ -n "$dest_name" ]]; then
    dest_file="${dest_dir}/${dest_name}"
  else
    dest_file="${dest_dir}/$(basename "$src")"
  fi

  if $DRY_RUN; then
    echo -e "  ${YELLOW}→${NC} $src  ⟶  ${dest_file#"$TARGET/"}"
    (( COPIED++ )) || true
    return
  fi

  mkdir -p "$dest_dir"
  cp "$src_path" "$dest_file"
  echo -e "  ${GREEN}✓${NC} ${dest_file#"$TARGET/"}"
  (( COPIED++ )) || true
}

deploy_dir() {
  local src_dir="$1" dest_dir="$2"
  local src_path="${BIOS_SRC}/${src_dir}"

  [[ -d "$src_path" ]] || { echo "  - manquant : $src_dir/"; return; }

  if $DRY_RUN; then
    find "$src_path" -type f | while read -r f; do
      local rel="${f#"$src_path/"}"
      echo -e "  ${YELLOW}→${NC} ${src_dir}/${rel}  ⟶  ${dest_dir#"$TARGET/"}/${rel}"
    done
    return
  fi

  mkdir -p "$dest_dir"
  cp -r "$src_path/." "$dest_dir/"
  local count
  count=$(find "$src_path" -type f | wc -l | tr -d ' ')
  echo -e "  ${GREEN}✓${NC} ${dest_dir#"$TARGET/"}/  ($count fichiers)"
  (( COPIED += count )) || true
}

# ── déploiement ────────────────────────────────────────────────────────────

echo "── Sega ───────────────────────────────────────────────────────────────"
deploy "dc/dc_boot.bin"   "${BIOS_DEST}/dc"
deploy "dc/dc_flash.bin"  "${BIOS_DEST}/dc"
deploy "saturn_bios.bin"  "${BIOS_DEST}"
deploy "BIOS_CD_E.BIN"    "${BIOS_DEST}"
deploy "BIOS_CD_J.BIN"    "${BIOS_DEST}"
deploy "BIOS_CD_U.BIN"    "${BIOS_DEST}"
deploy "32X_G_BIOS.BIN"   "${BIOS_DEST}"
deploy "32X_M_BIOS.BIN"   "${BIOS_DEST}"
deploy "32X_S_BIOS.BIN"   "${BIOS_DEST}"
deploy "bios_MD.bin"      "${BIOS_DEST}"
deploy "bios.gg"          "${BIOS_DEST}"
deploy "bios_eu.gg"       "${BIOS_DEST}"
deploy "bios_J.sms"       "${BIOS_DEST}"
deploy "bios_U.sms"       "${BIOS_DEST}"
deploy "bios_E.sms"       "${BIOS_DEST}"

echo ""
echo "── Nintendo ───────────────────────────────────────────────────────────"
deploy "gb_bios.bin"      "${BIOS_DEST}"
deploy "gbc_bios.bin"     "${BIOS_DEST}"
deploy "gba_bios.bin"     "${BIOS_DEST}"
deploy "BIOSGBA.ROM"      "${BIOS_DEST}"
deploy "biosnds7.rom"     "${BIOS_DEST}"
deploy "biosnds9.rom"     "${BIOS_DEST}"
deploy "firmware.bin"     "${BIOS_DEST}"
deploy "DISKSYS.ROM"      "${BIOS_DEST}"
deploy "GC/USA/IPL.bin"   "${BIOS_DEST}/GC/USA"
deploy "GC/EUR/IPL.bin"   "${BIOS_DEST}/GC/EUR"
deploy "GC/JAP/IPL.bin"   "${BIOS_DEST}/GC/JAP"
deploy_dir "bsnes-bios"   "${BIOS_DEST}/bsnes-bios"

echo ""
echo "── Sony ───────────────────────────────────────────────────────────────"
deploy "scph1001.bin"     "${BIOS_DEST}"

echo ""
echo "── Atari ──────────────────────────────────────────────────────────────"
deploy "5200.rom"         "${BIOS_DEST}"
deploy "7800.rom"         "${BIOS_DEST}"
deploy "lynxboot.img"     "${BIOS_DEST}"
deploy "Jaguar.rom"       "${BIOS_DEST}"
deploy "jagboot.rom"      "${BIOS_DEST}"
deploy "jagcd.rom"        "${BIOS_DEST}"
deploy "tos.img"          "${BIOS_DEST}"

echo ""
echo "── Autres ─────────────────────────────────────────────────────────────"
deploy "FZ-10.bin"        "${BIOS_DEST}"
deploy "neo-geo.rom"      "${BIOS_DEST}"
deploy "ng-lo.rom"        "${BIOS_DEST}"
deploy "ng-sfix.rom"      "${BIOS_DEST}"
deploy "ng-sm1.rom"       "${BIOS_DEST}"
deploy "mac.rom"          "${BIOS_DEST}"

echo ""
echo "── Amiga (kickstarts) ─────────────────────────────────────────────────"
# Les kickstarts vont dans un dossier spécial d'Amiberry, pas dans bios/
KICKSTART_DEST="${TARGET}/game-data/amiberry/kickstarts"
deploy_dir "kickstarts"   "${KICKSTART_DEST}"

echo ""
echo "── MAME BIOS ──────────────────────────────────────────────────────────"
# Les BIOS MAME se placent dans le dossier mame/ des ROMs, pas dans bios/
MAME_DEST="${TARGET}/mame"
echo "  Note : les BIOS MAME vont dans le dossier ROMs MAME, pas dans bios/"
deploy_dir "mame"         "${MAME_DEST}"

# ── résumé ─────────────────────────────────────────────────────────────────

echo ""
echo "─────────────────────────────────────────────────────────────────────"
if $DRY_RUN; then
  echo -e "  Simulation terminée — ${COPIED} fichier(s) seraient copiés."
  echo "  Relance sans --dry-run pour copier réellement."
else
  echo -e "  ${GREEN}Déploiement terminé — ${COPIED} fichier(s) copiés vers $TARGET${NC}"
fi
echo ""
