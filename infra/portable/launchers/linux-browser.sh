#!/usr/bin/env bash

# Copyright 2026 The Chromium Authors, the AUR, Alex313031, and gz83.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -euo pipefail

WRAPPER="$(readlink -f -- "${BASH_SOURCE[0]}")"
HERE="$(dirname -- "$WRAPPER")"
PROFILE="$HERE/.config/thorium"
CACHE="$HERE/.config/cache"
FLAGS_FILE="$HERE/.config/thorium-flags.conf"

export CHROME_WRAPPER="$WRAPPER"
export CHROME_DESKTOP="thorium-portable.desktop"
export CHROME_VERSION_EXTRA="stable, (Portable)"
export GNOME_DISABLE_CRASH_DIALOG=SET_BY_THORIUM
export LD_LIBRARY_PATH="$HERE/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

usage() {
  cat <<'EOF'
Usage: THORIUM-PORTABLE [--temp-profile] [--safe-mode] [options] [URL]

  --temp-profile  Use a new profile and remove it after Thorium exits.
  --safe-mode     Disable chrome://flags experiments for this launch.
  -h, --help      Show this help.

Additional options are passed directly to Thorium.
EOF
}

temporary_profile=""
safe_mode=false

cleanup_temporary_profile() {
  local exit_code=$?
  if [[ -n "$temporary_profile" ]] &&
    ! rm -rf -- "$temporary_profile"; then
    echo "warning: could not remove temporary profile: $temporary_profile" >&2
  fi
  return "$exit_code"
}

while (($#)); do
  case "$1" in
    -h | -help | --help)
      usage
      exit 0
      ;;
    --temp-profile)
      if [[ -n "$temporary_profile" ]]; then
        echo "error: --temp-profile may only be specified once" >&2
        exit 2
      fi
      temporary_profile="$(mktemp -d -t thorium-portable.XXXXXXXX)"
      trap cleanup_temporary_profile EXIT
      PROFILE="$temporary_profile"
      CACHE="$temporary_profile/cache"
      shift
      ;;
    --safe-mode)
      safe_mode=true
      shift
      ;;
    --)
      shift
      break
      ;;
    *)
      break
      ;;
  esac
done

mkdir -p -- "$PROFILE" "$CACHE"
pending_crashes="$PROFILE/Crash Reports/pending"
if [[ -d "$pending_crashes" ]]; then
  find "$pending_crashes" -type f -mtime +30 \
    \( -name '*.meta' -o -name '*.dmp' \) -delete
fi

declare -a user_flags=()
if [[ -f "$FLAGS_FILE" ]]; then
  while IFS= read -r flag || [[ -n "$flag" ]]; do
    flag="${flag%$'\r'}"
    [[ -z "$flag" || "$flag" == \#* ]] || user_flags+=("$flag")
  done < "$FLAGS_FILE"
fi
if $safe_mode; then
  user_flags+=("--no-experiments")
fi

command=(
  "$HERE/thorium"
  "--class=thorium-portable"
  "--disable-machine-id"
  "--disable-encryption"
  "--user-data-dir=$PROFILE"
  "--disk-cache-dir=$CACHE"
  "${user_flags[@]}"
  "$@"
)

# Prevent untrusted child processes from directly inheriting the invoking
# terminal's standard file descriptors. Keep this aligned with Chromium's
# Linux wrapper.
exec < /dev/null
exec > >(exec cat)
exec 2> >(exec cat >&2)

if [[ -n "$temporary_profile" ]]; then
  echo "Using temporary profile: $temporary_profile"
  "${command[@]}"
else
  exec -a "$0" "${command[@]}"
fi
