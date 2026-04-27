#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Bump PKG_VERSION (and PKG_SHA256) for all tracked AmberELEC packages.
#
# Handles two URL patterns found in package.mk files:
#   Pattern A  PKG_URL="${PKG_SITE}.git"             → git clone, no SHA256
#   Pattern B  PKG_URL="${PKG_SITE}/archive/...gz"   → tarball,  SHA256 required
#
# Respects PKG_GIT_CLONE_BRANCH when set.

set -euo pipefail

# ── helpers ────────────────────────────────────────────────────────────────

log()  { echo "  $*"; }
ok()   { echo "✓ $*"; }
skip() { echo "– $*"; }
warn() { echo "! $*" >&2; }
die()  { echo "ERROR: $*" >&2; exit 1; }

command -v curl >/dev/null || die "curl is required"
command -v git  >/dev/null || die "git is required"

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

# Portable in-place sed (avoids sed -i portability issues between macOS/Linux)
sedi() {
  local tmp file
  tmp=$(mktemp /tmp/sedi.XXXXXX) || return 1
  file="${@: -1}"
  sed "${@:1:$#-1}" "${file}" > "${tmp}"
  mv "${tmp}" "${file}"
}

# ── options ────────────────────────────────────────────────────────────────

DRY_RUN=false
ONLY_RA=false
ONLY_CORES=false
TARGET_CORE=""
REPORT_FILE="bump_report.log"

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

  --dry-run        Show what would change without modifying files
  --only-ra        Only bump RetroArch and its companion packages
  --only-cores     Only bump libretro cores (skip RetroArch)
  --core <name>    Bump a single package by name
  --help           Show this message

Environment:
  GITHUB_TOKEN     GitHub token (raises rate limit from 60 to 5000 req/h)

Examples:
  ./bump_amberelec.sh --dry-run
  ./bump_amberelec.sh --only-ra
  ./bump_amberelec.sh --core snes9x
  GITHUB_TOKEN=ghp_xxx ./bump_amberelec.sh
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)    DRY_RUN=true ;;
    --only-ra)    ONLY_RA=true ;;
    --only-cores) ONLY_CORES=true ;;
    --core)       [[ -n "${2:-}" ]] || die "--core requires a name"; TARGET_CORE="$2"; shift ;;
    --help|-h)    usage ;;
    *) die "Unknown option: $1. Try --help." ;;
  esac
  shift
done

# ── package lists ──────────────────────────────────────────────────────────

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
BLOCKLIST="${REPO_ROOT}/config/blocklist"

# RetroArch itself lives in packages/games/tools/retroarch, not in libretro/
RA_PACKAGES=(retroarch retroarch-assets libretro-database core-info glsl-shaders)

EMU_PACKAGES=(
  scummvmsa advancemame hypseus-singe amiberry hatarisa openbor lzdoom gzdoom
  raze zmusic mupen64plussa-audio-sdl mupen64plussa-core mupen64plussa-input-sdl
  mupen64plussa-rsp-hle mupen64plussa-ui-console mupen64plussa-video-glide64mk2
  mupen64plussa-video-rice hydracastlelabyrinth sdlpop opentyrian
)

# Derive libretro core list from directory structure — avoids parsing the
# multiline LIBRETRO_CORES variable in packages/amberelec/package.mk
libretro_cores() {
  ls "${REPO_ROOT}/packages/games/libretro/"
}

if [[ -n "${TARGET_CORE}" ]]; then
  PACKAGES_ALL=("${TARGET_CORE}")
elif $ONLY_RA; then
  PACKAGES_ALL=("${RA_PACKAGES[@]}")
elif $ONLY_CORES; then
  mapfile -t _cores < <(libretro_cores)
  PACKAGES_ALL=("${_cores[@]}" "${EMU_PACKAGES[@]}")
else
  mapfile -t _cores < <(libretro_cores)
  PACKAGES_ALL=("${RA_PACKAGES[@]}" "${_cores[@]}" "${EMU_PACKAGES[@]}")
fi

# ── fetch helpers ──────────────────────────────────────────────────────────

# Get the HEAD commit hash for a git remote + optional branch.
# Stores git ls-remote output in a temp file to avoid SIGPIPE from early awk exit.
latest_hash() {
  local site="$1" branch="${2:-}"
  local ref tmp
  [[ -n "${branch}" ]] && ref="refs/heads/${branch}" || ref="HEAD"
  tmp=$(mktemp /tmp/bump_lsremote.XXXXXX)
  git ls-remote "${site}" > "${tmp}" 2>/dev/null || { rm -f "${tmp}"; echo ""; return 0; }
  awk -v r="${ref}" '$2 == r { print substr($1,1,40); exit }' "${tmp}"
  rm -f "${tmp}"
}

# Download a tarball and return its SHA256; prints empty string on failure
download_sha256() {
  local url="$1"
  local tmp curl_args
  tmp=$(mktemp /tmp/bump_pkg.XXXXXX.tar.gz)
  curl_args=(-fsSL -o "${tmp}")
  [[ -n "${GITHUB_TOKEN:-}" ]] && curl_args+=(-H "Authorization: token ${GITHUB_TOKEN}")
  if ! curl "${curl_args[@]}" "${url}" 2>/dev/null; then
    rm -f "${tmp}"
    echo ""
    return 1
  fi
  local hash
  hash=$(sha256_file "${tmp}")
  rm -f "${tmp}"
  echo "${hash}"
}

# Extract PKG_* variable assignments from a package.mk without sourcing the
# whole file (which would require the full build system environment).
parse_pkg_vars() {
  grep -E '^PKG_(NAME|VERSION|SHA256|SITE|URL|GIT_CLONE_BRANCH|GIT_BRANCH)=' "$1" || true
}

is_blocklisted() {
  [[ -f "${BLOCKLIST}" ]] && grep -qx "$1" "${BLOCKLIST}" 2>/dev/null
}

# ── core bump function ─────────────────────────────────────────────────────

bump_package() {
  local pkg="$1"

  local f
  f=$(find "${REPO_ROOT}/packages" -wholename "*/${pkg}/package.mk" 2>/dev/null | head -1)
  if [[ -z "${f}" ]]; then
    warn "${pkg}: package.mk not found"
    printf "%-40s %s\n" "${pkg}" "NOT_FOUND" >> "${REPORT_FILE}"
    return
  fi

  if is_blocklisted "${pkg}"; then
    skip "${pkg}: blocklisted"
    printf "%-40s %s\n" "${pkg}" "BLOCKLISTED" >> "${REPORT_FILE}"
    return
  fi

  # Load package variables. Eval in order so PKG_URL can reference PKG_SITE.
  local PKG_NAME PKG_VERSION PKG_SITE PKG_URL PKG_GIT_CLONE_BRANCH PKG_GIT_BRANCH PKG_SHA256
  PKG_NAME="" PKG_VERSION="" PKG_SITE="" PKG_URL=""
  PKG_GIT_CLONE_BRANCH="" PKG_GIT_BRANCH="" PKG_SHA256=""
  eval "$(parse_pkg_vars "${f}")"

  if [[ -z "${PKG_VERSION}" || -z "${PKG_SITE}" ]]; then
    warn "${pkg}: cannot parse PKG_VERSION / PKG_SITE from ${f}"
    printf "%-40s %s\n" "${pkg}" "PARSE_ERROR" >> "${REPORT_FILE}"
    return
  fi

  local branch="${PKG_GIT_CLONE_BRANCH:-${PKG_GIT_BRANCH:-}}"

  local new_hash
  new_hash=$(latest_hash "${PKG_SITE}" "${branch}")
  if [[ -z "${new_hash}" ]]; then
    warn "${pkg}: cannot reach ${PKG_SITE} (branch: ${branch:-HEAD})"
    printf "%-40s %s\n" "${pkg}" "FETCH_ERROR" >> "${REPORT_FILE}"
    return
  fi

  if [[ "${new_hash}" == "${PKG_VERSION}" ]]; then
    skip "${pkg}: up to date (${PKG_VERSION:0:10}...)"
    printf "%-40s %s\n" "${pkg}" "UP_TO_DATE" >> "${REPORT_FILE}"
    return
  fi

  log "${pkg}: ${PKG_VERSION:0:10}... → ${new_hash:0:10}..."

  # ── Pattern A: .git URL — update PKG_VERSION, remove PKG_SHA256 ───────
  if [[ "${PKG_URL}" =~ \.git$ ]]; then
    if $DRY_RUN; then
      printf "%-40s WOULD_UPDATE (git)     %s → %s\n" \
        "${pkg}" "${PKG_VERSION:0:10}" "${new_hash:0:10}" >> "${REPORT_FILE}"
      return
    fi
    sedi "s/PKG_VERSION=\"${PKG_VERSION}\"/PKG_VERSION=\"${new_hash}\"/" "${f}"
    if grep -q "^PKG_SHA256=" "${f}"; then
      sedi "/^PKG_SHA256=/d" "${f}"
    fi
    ok "${pkg}: updated (git clone)"
    printf "%-40s UPDATED (git)          %s → %s\n" \
      "${pkg}" "${PKG_VERSION:0:10}" "${new_hash:0:10}" >> "${REPORT_FILE}"
    return
  fi

  # ── Pattern B: archive tarball — update PKG_VERSION + PKG_SHA256 ──────
  local new_url="${PKG_SITE}/archive/${new_hash}.tar.gz"
  log "${pkg}: downloading ${new_url}..."

  local new_sha256
  new_sha256=$(download_sha256 "${new_url}")
  if [[ -z "${new_sha256}" ]]; then
    warn "${pkg}: archive download failed — skipping SHA256 update"
    printf "%-40s %s\n" "${pkg}" "DOWNLOAD_ERROR" >> "${REPORT_FILE}"
    return
  fi

  if $DRY_RUN; then
    printf "%-40s WOULD_UPDATE (archive) %s → %s  sha=%s...\n" \
      "${pkg}" "${PKG_VERSION:0:10}" "${new_hash:0:10}" "${new_sha256:0:16}" >> "${REPORT_FILE}"
    return
  fi

  sedi "s/PKG_VERSION=\"${PKG_VERSION}\"/PKG_VERSION=\"${new_hash}\"/" "${f}"
  if grep -q "^PKG_SHA256=" "${f}"; then
    sedi "s/^PKG_SHA256=\"[^\"]*\"/PKG_SHA256=\"${new_sha256}\"/" "${f}"
  fi

  ok "${pkg}: updated (archive) sha=${new_sha256:0:16}..."
  printf "%-40s UPDATED (archive)      %s → %s\n" \
    "${pkg}" "${PKG_VERSION:0:10}" "${new_hash:0:10}" >> "${REPORT_FILE}"
}

# ── main ───────────────────────────────────────────────────────────────────

{
  echo "AmberELEC package bump — $(date)"
  if $DRY_RUN; then echo "(DRY RUN — files not modified)"; fi
  echo ""
  printf "%-40s %s\n" "PACKAGE" "STATUS"
  printf "%-40s %s\n" "$(printf '%0.s-' {1..40})" "$(printf '%0.s-' {1..30})"
} > "${REPORT_FILE}"

echo "=== AmberELEC package bump ==="
if $DRY_RUN; then echo "    [DRY RUN — files will not be modified]"; fi
echo ""

for pkg in "${PACKAGES_ALL[@]}"; do
  bump_package "${pkg}"
done

echo ""
echo "Report: ${REPORT_FILE}"
