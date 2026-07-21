#!/usr/bin/env bash

# Copyright (c) 2026 Alex313031 and gz83.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -euo pipefail

WRAPPER="$(readlink -f -- "${BASH_SOURCE[0]}")"
HERE="$(dirname -- "$WRAPPER")"
PROFILE="$HERE/.config/thorium-shell"
CACHE="$HERE/.config/cache-shell"

mkdir -p -- "$PROFILE" "$CACHE"
export LD_LIBRARY_PATH="$HERE/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

# Prevent untrusted child processes from directly inheriting the invoking
# terminal's standard file descriptors. Keep this aligned with Chromium's
# Linux wrapper.
exec < /dev/null
exec > >(exec cat)
exec 2> >(exec cat >&2)

exec -a "$0" "$HERE/thorium_shell" \
  "--disable-machine-id" \
  "--disable-encryption" \
  "--user-data-dir=$PROFILE" \
  "--disk-cache-dir=$CACHE" \
  "--enable-experimental-web-platform-features" \
  "--enable-clear-hevc-for-testing" \
  "$@"
