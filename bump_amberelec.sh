#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Bump PKG_VERSION (and PKG_SHA256) for all tracked AmberELEC packages.
#
# Handles three URL patterns found in package.mk files:
#   Pattern A  PKG_URL="${PKG_SITE}.git"             → git clone, no SHA256
#   Pattern B  PKG_URL="${PKG_SITE}/archive/...gz"   → tarball,  SHA256 required
#   Pattern C  PKG_VERSION="1.2.3" (semver)          → latest git tag, SHA256 required
#
# When PKG_URL is a GitHub archive URL, the git remote is extracted from it
# directly — PKG_SITE may point to a project website rather than a git host.
#
# Packages are silently skipped (no report entry) when they cannot be bumped
# by design: dynamic versions (derived from a parent package), virtual
# meta-packages, or static binary URLs with no git remote.
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

TMPDIR_BUMP=$(mktemp -d /tmp/bump.XXXXXX)
trap 'rm -rf "${TMPDIR_BUMP}"' EXIT INT TERM

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
  tmp=$(mktemp "${TMPDIR_BUMP}/sedi.XXXXXX") || return 1
  file="${@: -1}"
  sed "${@:1:$#-1}" "${file}" > "${tmp}"
  mv "${tmp}" "${file}"
}

# ── options ────────────────────────────────────────────────────────────────

DRY_RUN=false
ONLY_RA=false
ONLY_CORES=false
TARGET_CORE=""
JOBS=1
REPORT_FILE="bump_report.log"

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

  --dry-run        Show what would change without modifying files
  --only-ra        Only bump RetroArch and its companion packages
  --only-cores     Only bump libretro cores and standalone emulators/ports (skip RetroArch)
  --core <name>    Bump a single package by name
  --jobs <n>       Process up to N packages in parallel (default: 1)
  --help           Show this message

Environment:
  GITHUB_TOKEN     GitHub token (raises rate limit from 60 to 5000 req/h)

Examples:
  ./bump_amberelec.sh --dry-run
  ./bump_amberelec.sh --only-ra
  ./bump_amberelec.sh --core snes9x
  ./bump_amberelec.sh --jobs 8
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
    --jobs)       [[ "${2:-}" =~ ^[1-9][0-9]*$ ]] || die "--jobs requires a positive integer"; JOBS="$2"; shift ;;
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

# Derive libretro core list from directory structure — avoids parsing the
# multiline LIBRETRO_CORES variable in packages/amberelec/package.mk
libretro_cores() {
  find "${REPO_ROOT}/packages/games/libretro" -maxdepth 1 -mindepth 1 -type d \
    | sed 's|.*/||'
}

# Discover standalone emulators and ports from the directory tree.
# Searches games/emulators/ and games/ports/ at any depth; -mindepth 2
# skips the games/ports/package.mk meta-package at depth 1.
emu_packages() {
  find "${REPO_ROOT}/packages/games/emulators" \
       "${REPO_ROOT}/packages/games/ports" \
    -mindepth 2 -name "package.mk" \
    | sed 's|.*/\([^/]*\)/package\.mk$|\1|' \
    | sort -u
}

if [[ -n "${TARGET_CORE}" ]]; then
  PACKAGES_ALL=("${TARGET_CORE}")
elif $ONLY_RA; then
  PACKAGES_ALL=("${RA_PACKAGES[@]}")
elif $ONLY_CORES; then
  mapfile -t _cores < <(libretro_cores)
  mapfile -t _emus  < <(emu_packages)
  mapfile -t PACKAGES_ALL < <(printf '%s\n' "${_cores[@]}" "${_emus[@]}" | awk '!seen[$0]++')
else
  mapfile -t _cores < <(libretro_cores)
  mapfile -t _emus  < <(emu_packages)
  mapfile -t PACKAGES_ALL < <(printf '%s\n' "${RA_PACKAGES[@]}" "${_cores[@]}" "${_emus[@]}" | awk '!seen[$0]++')
fi

# ── fetch helpers ──────────────────────────────────────────────────────────

# Get the HEAD commit hash for a git remote + optional branch.
# Stores git ls-remote output in a temp file to avoid SIGPIPE from early awk exit.
latest_hash() {
  local site="$1" branch="${2:-}"
  local ref tmp
  [[ -n "${branch}" ]] && ref="refs/heads/${branch}" || ref="HEAD"
  tmp=$(mktemp "${TMPDIR_BUMP}/lsremote.XXXXXX")
  git ls-remote "${site}" > "${tmp}" 2>/dev/null || { rm -f "${tmp}"; echo ""; return 0; }
  awk -v r="${ref}" '$2 == r { print substr($1,1,40); exit }' "${tmp}"
  rm -f "${tmp}"
}

# Get the latest semver tag from a git remote (strips leading 'v', e.g. "1.13.1").
# Only considers pure numeric dot-separated tags; ignores pre-release suffixes.
latest_semver_tag() {
  local site="$1"
  git ls-remote --tags "${site}" 2>/dev/null \
    | awk '{print $2}' \
    | grep -E '^refs/tags/v?[0-9]+\.[0-9]+(\.[0-9]+)*$' \
    | sed 's|refs/tags/||' | sed 's|^v||' \
    | sort -t. -k1,1n -k2,2n -k3,3n -k4,4n \
    | tail -1
}

# Download a tarball and return its SHA256; prints empty string on failure
download_sha256() {
  local url="$1"
  local tmp curl_args
  tmp=$(mktemp "${TMPDIR_BUMP}/pkg.XXXXXX")
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
  grep -E '^PKG_(NAME|VERSION|SHA256|SITE|URL|GIT_CLONE_BRANCH|GIT_BRANCH)=' "$1" \
    | grep -v '\$(' || true
}

# Returns the blocklist comment (reason) for a package, or empty string if not blocklisted.
blocklist_reason() {
  [[ -f "${BLOCKLIST}" ]] || return 0
  local line
  line=$(grep -E "^$1([[:space:]]|$)" "${BLOCKLIST}" 2>/dev/null | head -1) || true
  [[ -n "${line}" ]] && sed 's/^[^#]*#[[:space:]]*//' <<< "${line}" || true
}


# ── core bump function ─────────────────────────────────────────────────────

bump_package() {
  local pkg="$1" _report="${2:-${REPORT_FILE}}"

  local f
  f=$(find "${REPO_ROOT}/packages" -wholename "*/${pkg}/package.mk" 2>/dev/null | head -1)
  if [[ -z "${f}" ]]; then
    warn "${pkg}: package.mk not found"
    printf "%-40s %s\n" "${pkg}" "NOT_FOUND" >> "${_report}"
    return
  fi

  local _bl_reason
  _bl_reason=$(blocklist_reason "${pkg}")
  if [[ -n "${_bl_reason}" ]]; then
    skip "${pkg}: blocklisted (${_bl_reason})"
    return
  fi

  # PKG_VERSION="$(get_pkg_version foo)": version derived at build time from a
  # parent package — no independent bump needed, follows parent automatically.
  if grep -qE '^PKG_VERSION=.*\$\(' "${f}" 2>/dev/null; then
    skip "${pkg}: dynamic version (follows parent package)"
    return
  fi

  # Virtual meta-packages have no version or URL of their own.
  if grep -q '^PKG_SECTION="virtual"' "${f}" 2>/dev/null; then
    skip "${pkg}: virtual meta-package"
    return
  fi

  # Load package variables. Eval in order so PKG_URL can reference PKG_SITE.
  local PKG_NAME PKG_VERSION PKG_SITE PKG_URL PKG_GIT_CLONE_BRANCH PKG_GIT_BRANCH PKG_SHA256
  PKG_NAME="" PKG_VERSION="" PKG_SITE="" PKG_URL=""
  PKG_GIT_CLONE_BRANCH="" PKG_GIT_BRANCH="" PKG_SHA256=""
  eval "$(parse_pkg_vars "${f}")"

  if [[ -z "${PKG_VERSION}" ]]; then
    warn "${pkg}: cannot parse PKG_VERSION from ${f}"
    printf "%-40s %s\n" "${pkg}" "PARSE_ERROR" >> "${_report}"
    return
  fi

  # No PKG_SITE means a static/binary URL with no git remote to query.
  if [[ -z "${PKG_SITE}" ]]; then
    skip "${pkg}: static URL, no git source to track"
    return
  fi

  local branch="${PKG_GIT_CLONE_BRANCH:-${PKG_GIT_BRANCH:-}}"

  # If PKG_URL is a GitHub archive, use the repo URL from it as the git remote
  # rather than PKG_SITE (which may point to a project website, not a git host).
  local git_remote="${PKG_SITE}"
  if [[ "${PKG_URL}" =~ ^(https://github\.com/[^/]+/[^/]+)/archive/ ]]; then
    git_remote="${BASH_REMATCH[1]}"
  fi

  # ── Pattern C: semver version (e.g. "1.11.0") — query latest git tag ──
  if [[ "${PKG_VERSION}" =~ ^[0-9]+\.[0-9]+ ]]; then
    local new_version
    new_version=$(latest_semver_tag "${git_remote}")
    if [[ -z "${new_version}" ]]; then
      warn "${pkg}: cannot fetch tags from ${git_remote}"
      printf "%-40s %s\n" "${pkg}" "FETCH_ERROR" >> "${_report}"
      return
    fi
    if [[ "${new_version}" == "${PKG_VERSION}" ]]; then
      skip "${pkg}: up to date (${PKG_VERSION})"
      printf "%-40s %s\n" "${pkg}" "UP_TO_DATE" >> "${_report}"
      return
    fi
    log "${pkg}: ${PKG_VERSION} → ${new_version}"
    # Detect whether the URL uses a "v" prefix (e.g. /archive/v1.11.0.tar.gz)
    local tag_prefix=""
    [[ "${PKG_URL}" == *"/v${PKG_VERSION}."* ]] && tag_prefix="v"
    local new_url="${git_remote}/archive/${tag_prefix}${new_version}.tar.gz"
    log "${pkg}: downloading ${new_url}..."
    local new_sha256
    new_sha256=$(download_sha256 "${new_url}")
    if [[ -z "${new_sha256}" ]]; then
      warn "${pkg}: archive download failed"
      printf "%-40s %s\n" "${pkg}" "DOWNLOAD_ERROR" >> "${_report}"
      return
    fi
    if $DRY_RUN; then
      printf "%-40s WOULD_UPDATE (semver)  %s → %s  sha=%s...\n" \
        "${pkg}" "${PKG_VERSION}" "${new_version}" "${new_sha256:0:16}" >> "${_report}"
      return
    fi
    sedi "s/PKG_VERSION=\"${PKG_VERSION//./\\.}\"/PKG_VERSION=\"${new_version}\"/" "${f}"
    if grep -q "^PKG_SHA256=" "${f}"; then
      sedi "s/^PKG_SHA256=\"[^\"]*\"/PKG_SHA256=\"${new_sha256}\"/" "${f}"
    fi
    ok "${pkg}: updated (semver) ${PKG_VERSION} → ${new_version}"
    printf "%-40s UPDATED (semver)       %s → %s\n" \
      "${pkg}" "${PKG_VERSION}" "${new_version}" >> "${_report}"
    return
  fi

  # ── Patterns A & B: commit-hash version ───────────────────────────────
  local new_hash
  new_hash=$(latest_hash "${git_remote}" "${branch}")
  if [[ -z "${new_hash}" ]]; then
    warn "${pkg}: cannot reach ${git_remote} (branch: ${branch:-HEAD})"
    printf "%-40s %s\n" "${pkg}" "FETCH_ERROR" >> "${_report}"
    return
  fi

  if [[ "${new_hash}" == "${PKG_VERSION}" ]]; then
    skip "${pkg}: up to date (${PKG_VERSION:0:10}...)"
    printf "%-40s %s\n" "${pkg}" "UP_TO_DATE" >> "${_report}"
    return
  fi

  log "${pkg}: ${PKG_VERSION:0:10}... → ${new_hash:0:10}..."

  # ── Pattern A: .git URL — update PKG_VERSION, remove PKG_SHA256 ───────
  if [[ "${PKG_URL}" =~ \.git$ ]]; then
    if $DRY_RUN; then
      printf "%-40s WOULD_UPDATE (git)     %s → %s\n" \
        "${pkg}" "${PKG_VERSION:0:10}" "${new_hash:0:10}" >> "${_report}"
      return
    fi
    sedi "s/PKG_VERSION=\"${PKG_VERSION//./\\.}\"/PKG_VERSION=\"${new_hash}\"/" "${f}"
    if grep -q "^PKG_SHA256=" "${f}"; then
      sedi "/^PKG_SHA256=/d" "${f}"
    fi
    ok "${pkg}: updated (git clone)"
    printf "%-40s UPDATED (git)          %s → %s\n" \
      "${pkg}" "${PKG_VERSION:0:10}" "${new_hash:0:10}" >> "${_report}"
    return
  fi

  # ── Pattern B: archive tarball — update PKG_VERSION + PKG_SHA256 ──────
  local new_url="${git_remote}/archive/${new_hash}.tar.gz"
  log "${pkg}: downloading ${new_url}..."

  local new_sha256
  new_sha256=$(download_sha256 "${new_url}")
  if [[ -z "${new_sha256}" ]]; then
    warn "${pkg}: archive download failed — skipping SHA256 update"
    printf "%-40s %s\n" "${pkg}" "DOWNLOAD_ERROR" >> "${_report}"
    return
  fi

  if $DRY_RUN; then
    printf "%-40s WOULD_UPDATE (archive) %s → %s  sha=%s...\n" \
      "${pkg}" "${PKG_VERSION:0:10}" "${new_hash:0:10}" "${new_sha256:0:16}" >> "${_report}"
    return
  fi

  sedi "s/PKG_VERSION=\"${PKG_VERSION//./\\.}\"/PKG_VERSION=\"${new_hash}\"/" "${f}"
  if grep -q "^PKG_SHA256=" "${f}"; then
    sedi "s/^PKG_SHA256=\"[^\"]*\"/PKG_SHA256=\"${new_sha256}\"/" "${f}"
  fi

  ok "${pkg}: updated (archive) sha=${new_sha256:0:16}..."
  printf "%-40s UPDATED (archive)      %s → %s\n" \
    "${pkg}" "${PKG_VERSION:0:10}" "${new_hash:0:10}" >> "${_report}"
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

if [[ "${JOBS}" -gt 1 ]]; then
  declare -a _pids=() _tmps=()
  _failed=0
  for pkg in "${PACKAGES_ALL[@]}"; do
    _tmp=$(mktemp "${TMPDIR_BUMP}/report.XXXXXX")
    _tmps+=("${_tmp}")
    bump_package "${pkg}" "${_tmp}" &
    _pids+=($!)
    # Drain the pool once it's full
    while [[ ${#_pids[@]} -ge "${JOBS}" ]]; do
      wait "${_pids[0]}" 2>/dev/null || _failed=$(( _failed + 1 ))
      _pids=("${_pids[@]:1}")
    done
  done
  for pid in "${_pids[@]}"; do
    wait "${pid}" 2>/dev/null || _failed=$(( _failed + 1 ))
  done
  # Merge report lines in launch order (avoids interleaved writes from subshells)
  for _tmp in "${_tmps[@]}"; do
    cat "${_tmp}" >> "${REPORT_FILE}"
  done
  [[ "${_failed}" -eq 0 ]] || warn "${_failed} package(s) had errors — see report"
else
  for pkg in "${PACKAGES_ALL[@]}"; do
    bump_package "${pkg}"
  done
fi

echo ""
echo "Report: ${REPORT_FILE}"
