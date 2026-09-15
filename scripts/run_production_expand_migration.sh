#!/usr/bin/env bash
# Run one approved, journaled production expand migration through the trusted launcher.
# This wrapper deliberately never invokes Alembic, Docker, or the internal deploy child.

set -euo pipefail
umask 077

readonly LAUNCHER="/usr/local/sbin/xjie-production-launch"

usage() {
  printf 'Usage: %s <40-character-main-sha>\n' "${0##*/}" >&2
}

if [[ "$#" -ne 1 ]]; then
  usage
  exit 64
fi

readonly EXPECTED_MAIN_SHA="$1"
if [[ ! "$EXPECTED_MAIN_SHA" =~ ^[0-9a-f]{40}$ ]]; then
  printf 'The main SHA must be exactly 40 lowercase hexadecimal characters.\n' >&2
  exit 64
fi

if [[ ! -x "$LAUNCHER" ]]; then
  printf 'Trusted production launcher is unavailable: %s\n' "$LAUNCHER" >&2
  exit 69
fi

unset xjie_github_token
cleanup() {
  unset xjie_github_token
}
trap cleanup EXIT HUP INT TERM

read -r -s -p 'GitHub token: ' xjie_github_token
printf '\n'

printf '%s\0' "$xjie_github_token" |
  "$LAUNCHER" \
    "$EXPECTED_MAIN_SHA" \
    expand-deploy \
    --confirm-expand-migration
