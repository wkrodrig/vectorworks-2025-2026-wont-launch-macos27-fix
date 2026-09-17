#!/bin/bash
# Read-only regression tests; do not access or modify installed applications.
set -euo pipefail
cd "$(dirname "$0")/.."
readonly SUPPORTED_YEARS=(2024 2025 2026)
EXPERIMENTAL=0
eval "$(/usr/bin/awk '
  /^(configure_version|select_version|confirm_experimental|list_backups)\(\) [{]/ { copying=1 }
  copying { print }
  copying && /^[}]/ { copying=0 }
' Fix-Vectorworks-iODBC.command)"
die() { printf '%s\n' "$*" >&2; exit 1; }
warn() { :; }
info() { :; }
is_version_installed() { [[ " $fixture " == *" $1 "* ]]; }
for fixture in '2024' '2025' '2026'; do
  VW_YEAR=""
  select_version
  [[ "$VW_YEAR" == "$fixture" ]]
  [[ "$BACKUP_ROOT" == "$HOME/Library/Application Support/Vectorworks $fixture iODBC Fix/backups" ]]
  [[ "$SUPPORT_BIN" == "/Applications/Vectorworks $fixture/Plug-ins/Support.vwlibrary/Contents/MacOS/Support" ]]
done
for fixture in '' '2024 2025' '2024 2026' '2025 2026' '2024 2025 2026'; do
  VW_YEAR=""
  if (select_version) </dev/null >/dev/null 2>&1; then
    die "Expected missing or ambiguous installation to fail: $fixture"
  fi
done
for VW_YEAR in 2024 2025 2026; do
  calls=0
  confirm() { calls=$((calls + 1)); return 0; }
  confirm_experimental
  if [[ "$VW_YEAR" == 2025 ]]; then [[ $calls -eq 0 ]]; else [[ $calls -eq 1 ]]; fi
done
VW_YEAR=2023
if (configure_version) >/dev/null 2>&1; then die 'Unsupported version was accepted'; fi
listed=""
list_backups_for_year() { listed="${listed:+$listed }$1"; return 0; }
list_backups
[[ "$listed" == '2024 2025 2026' ]]
printf 'PASS: version selection, isolated backup paths, experimental confirmation and backup listing\n'
