#!/bin/bash

# Repairs the Vectorworks 2024, 2025 or 2026 iODBC dependency on macOS 27 (Apple Silicon).
# Vectorworks 2025 is tested. Vectorworks 2024 and 2026 are experimental and unverified.
# Other standard installations can be explicitly selected with --experimental.
# This script does not disable SIP and does not write anything inside /usr/lib.
#
# Community workaround created by Wagner R. Ponce — ANIFONIX.
# Copyright (c) 2026 Wagner R. Ponce / ANIFONIX. Released under the MIT License.

set -euo pipefail
IFS=$'\n\t'

readonly OLD_DYLIB="/usr/lib/libiodbc.2.dylib"
readonly NEW_DYLIB="/opt/homebrew/opt/libiodbc/lib/libiodbc.2.dylib"
readonly BREW_BIN="/opt/homebrew/bin/brew"
readonly SUPPORTED_YEARS=(2024 2025 2026)

MODE="repair"
ASSUME_YES=0
LAUNCH=1
EXPERIMENTAL=0
SCAN=0
APP_SELECTION=""
GENERIC_BACKUP=0
VW_YEAR=""
VW_ROOT=""
VW_APP=""
SUPPORT_BUNDLE=""
SUPPORT_BIN=""
BACKUP_ROOT=""

info() { printf '\n[INFO] %s\n' "$*"; }
ok()   { printf '[OK]   %s\n' "$*"; }
warn() { printf '[WARNING] %s\n' "$*" >&2; }
die()  { printf '\n[ERROR] %s\n' "$*" >&2; exit 1; }

show_banner() {
  printf '\nVectorworks 2024/2025/2026 macOS 27 iODBC Fix\n'
  printf 'Other installations: opt-in --experimental dependency-based mode\n'
  printf 'Community workaround created by Wagner R. Ponce — ANIFONIX\n'
}

pause_if_double_clicked() {
  if [[ -t 0 && "${TERM_PROGRAM:-}" == "Apple_Terminal" ]]; then
    printf '\nPress Enter to close... '
    read -r _ || true
  fi
}

on_exit() {
  local status=$?
  if [[ $status -ne 0 ]]; then
    warn "The operation stopped before all steps were completed."
  fi
  pause_if_double_clicked
  exit "$status"
}
trap on_exit EXIT

usage() {
  cat <<'EOF'
Usage:
  Fix-Vectorworks-iODBC.command [options]

Options:
  --repair         Repair Vectorworks (default action).
  --verify         Check the current status without modifying anything.
  --rollback       Restore the most recent backup.
  --list-backups   List available backups.
  --version YEAR   Select Vectorworks 2024, 2025 or 2026.
  --experimental   Opt in to dependency-based detection of other installations.
  --app PATH       Select one exact .app path (requires --experimental).
  --scan           Read-only experimental discovery; does not install or repair.
  --yes, -y        Automatically approve required installations.
  --no-launch      Do not launch Vectorworks when finished.
  --help, -h       Display this help message.

Compatibility:
  Vectorworks 2024: experimental and not yet verified
  Vectorworks 2025: tested
  Vectorworks 2026: experimental and not yet verified

If one supported version is installed, it is selected automatically. Use
--version when multiple versions are installed or for unattended operation.
EOF
}

show_banner

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repair) MODE="repair" ;;
    --verify) MODE="verify"; LAUNCH=0 ;;
    --rollback) MODE="rollback"; LAUNCH=0 ;;
    --list-backups) MODE="list"; LAUNCH=0 ;;
    --experimental) EXPERIMENTAL=1 ;;
    --scan) SCAN=1; LAUNCH=0 ;;
    --app)
      [[ $# -ge 2 ]] || die "--app requires an absolute application path."
      APP_SELECTION="$2"; shift ;;
    --app=*) APP_SELECTION="${1#*=}" ;;
    --version)
      [[ $# -ge 2 ]] || die "--version requires 2024, 2025 or 2026."
      VW_YEAR="$2"
      shift
      ;;
    --version=*) VW_YEAR="${1#*=}" ;;
    --yes|-y) ASSUME_YES=1 ;;
    --no-launch) LAUNCH=0 ;;
    --help|-h) usage; exit 0 ;;
    *) usage; die "Unknown option: $1" ;;
  esac
  shift
done

[[ -z "$APP_SELECTION" || $EXPERIMENTAL -eq 1 ]] || die "--app requires --experimental."
[[ $SCAN -eq 0 || $EXPERIMENTAL -eq 1 ]] || die "--scan requires --experimental."
[[ $EXPERIMENTAL -eq 0 || -z "$VW_YEAR" ]] || die "Use --app, not --version, in experimental mode."
[[ $SCAN -eq 0 || "$MODE" == repair ]] || die "--scan cannot be combined with another action."

configure_app() {
  local app="$1" root leaf identity
  [[ "$app" == /Applications/Vectorworks*/*.app && -d "$app" && ! -L "$app" ]] || \
    die "Select an existing Vectorworks .app inside its standard /Applications/Vectorworks folder."
  root="${app%/*}"
  [[ "${root%/*}" == /Applications && ! -L "$root" ]] || die "Nested or symbolic-link installation folders are not supported."
  leaf="${app##*/}"
  [[ "$leaf" =~ ^Vectorworks\ [0-9]{4}\.app$ ]] || die "Select the main Vectorworks YEAR.app, not an updater or installer."
  identity="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Contents/Info.plist" 2>/dev/null)" || die "Application metadata could not be read."
  [[ "$identity" == *[Vv]ectorworks* ]] || die "Application metadata does not identify Vectorworks."
  VW_ROOT="$root"
  VW_APP="$app"
  VW_YEAR="${root##*/}"
  SUPPORT_BUNDLE=""
  if [[ -d "$root/Plug-ins/Support.vwlibrary" ]]; then
    SUPPORT_BUNDLE="$root/Plug-ins/Support.vwlibrary"
  elif [[ -d "$root/Plug-Ins/Support.vwlibrary" ]]; then
    SUPPORT_BUNDLE="$root/Plug-Ins/Support.vwlibrary"
  else
    die "Support.vwlibrary was not found alongside the selected application."
  fi
  [[ ! -L "${SUPPORT_BUNDLE%/*}" && ! -L "$SUPPORT_BUNDLE" && ! -L "$SUPPORT_BUNDLE/Contents" && ! -L "$SUPPORT_BUNDLE/Contents/MacOS" && ! -L "$SUPPORT_BUNDLE/Contents/MacOS/Support" ]] || die "Symbolic-link Support layouts are not supported."
  SUPPORT_BIN="$SUPPORT_BUNDLE/Contents/MacOS/Support"
  # Keep the existing backup namespace for exact standard 2024/2025/2026 apps.
  case "$app" in
    "/Applications/Vectorworks 2024/Vectorworks 2024.app"|"/Applications/Vectorworks 2025/Vectorworks 2025.app"|"/Applications/Vectorworks 2026/Vectorworks 2026.app")
      VW_YEAR="${root##* }"
      GENERIC_BACKUP=0
      BACKUP_ROOT="$HOME/Library/Application Support/Vectorworks $VW_YEAR iODBC Fix/backups" ;;
    *)
      GENERIC_BACKUP=1
      identity="$(printf '%s' "$app" | /usr/bin/shasum -a 256)"
      identity="${identity%% *}"
      BACKUP_ROOT="$HOME/Library/Application Support/Vectorworks Experimental iODBC Fix/$identity/backups" ;;
  esac
}

dependency_version() {
  local wanted="$1" dependencies
  dependencies="$(/usr/bin/otool -arch arm64 -L "$SUPPORT_BIN" 2>/dev/null)" || return 1
  /usr/bin/awk -v wanted="$wanted" '$1 == wanted { for (i=2;i<=NF;i++) if ($i == "version") { value=$(i+1); sub(/,$/, "", value); print value; exit } }' <<< "$dependencies"
}

experimental_candidate() {
  local app="$1" executable archs required
  configure_app "$app"
  check_paths
  executable="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$VW_APP/Contents/Info.plist" 2>/dev/null)" || die "Main executable metadata is missing."
  [[ -n "$executable" && "$executable" != */* && "$executable" != . && "$executable" != .. ]] || die "Invalid main executable name."
  archs="$(/usr/bin/lipo -archs "$VW_APP/Contents/MacOS/$executable" 2>/dev/null)" || die "Main executable could not be inspected."
  [[ " $archs " == *" arm64 "* ]] || die "The main executable does not contain arm64 code."
  required="$(dependency_version "$OLD_DYLIB")"
  if [[ -z "$required" ]]; then required="$(dependency_version "$NEW_DYLIB")"; fi
  [[ "$required" == 4.0.0 ]] || die "The arm64 dependency is not the exact original/Homebrew iODBC reference with required compatibility 4.0.0. Other patches (including @loader_path) are not supported."
}

discover_experimental() {
  local app
  CANDIDATES=()
  for app in /Applications/Vectorworks*/*.app; do
    [[ -d "$app" ]] || continue
    if (experimental_candidate "$app") >/dev/null 2>&1; then
      CANDIDATES+=("$app")
      printf '[CANDIDATE] %s\n' "$app"
    else
      printf '[SKIPPED] %s (unsupported layout, architecture or dependency)\n' "$app"
    fi
  done
}

select_experimental() {
  local answer index
  if [[ -n "$APP_SELECTION" ]]; then
    experimental_candidate "$APP_SELECTION"
    return
  fi
  discover_experimental
  [[ ${#CANDIDATES[@]} -gt 0 ]] || die "No eligible installations were found. Nothing was changed."
  [[ -t 0 ]] || die "Select one installation explicitly with --app PATH."
  for ((index=0; index<${#CANDIDATES[@]}; index++)); do
    printf '%s) %s\n' "$((index + 1))" "${CANDIDATES[$index]}"
  done
  printf 'Choose ONE installation by number: '
  read -r answer
  [[ "$answer" =~ ^[1-9][0-9]*$ && ${#answer} -le 4 ]] || die "Invalid selection."
  [[ $answer -le ${#CANDIDATES[@]} ]] || die "Invalid selection."
  experimental_candidate "${CANDIDATES[$((answer - 1))]}"
}

configure_version() {
  case "$VW_YEAR" in
    2024|2025|2026) ;;
    *) die "Unsupported Vectorworks version: ${VW_YEAR:-not specified}. Choose 2024, 2025 or 2026." ;;
  esac

  VW_ROOT="/Applications/Vectorworks $VW_YEAR"
  VW_APP="$VW_ROOT/Vectorworks $VW_YEAR.app"
  SUPPORT_BUNDLE="$VW_ROOT/Plug-ins/Support.vwlibrary"
  SUPPORT_BIN="$SUPPORT_BUNDLE/Contents/MacOS/Support"
  BACKUP_ROOT="$HOME/Library/Application Support/Vectorworks $VW_YEAR iODBC Fix/backups"
}

is_version_installed() {
  [[ -d "/Applications/Vectorworks $1" ]]
}

select_version() {
  if [[ -n "$VW_YEAR" ]]; then
    configure_version
    return
  fi

  local year answer="" choices="" installed=()
  for year in "${SUPPORTED_YEARS[@]}"; do
    if is_version_installed "$year"; then
      installed+=("$year")
      choices="${choices:+$choices/}$year"
    fi
  done

  if [[ ${#installed[@]} -eq 1 ]]; then
    VW_YEAR="${installed[0]}"
  elif [[ ${#installed[@]} -gt 1 ]]; then
    [[ -t 0 ]] || die "Multiple versions are installed ($choices). Add --version YEAR to select one."
    printf 'Multiple Vectorworks versions are installed. Which version should be used? [%s]: ' "$choices"
    read -r answer
    is_version_installed "$answer" || die "The selected version is not installed: $answer"
    VW_YEAR="$answer"
  else
    die "Vectorworks 2024, 2025 or 2026 was not found in /Applications."
  fi
  configure_version
}

check_macos_version() {
  local os_version os_major
  os_version="$(/usr/bin/sw_vers -productVersion)"
  os_major="${os_version%%.*}"
  [[ "$os_major" == "27" ]] || die "This workaround is intended only for macOS 27. Detected: macOS $os_version."
  ok "macOS $os_version detected."
}

confirm_experimental() {
  if [[ $EXPERIMENTAL -eq 1 ]]; then
    warn "Dependency-based EXPERIMENTAL mode: $VW_APP"
    warn "Passing these checks does not guarantee startup or full macOS 27 compatibility."
    [[ $ASSUME_YES -eq 0 ]] || die "Experimental repair requires interactive confirmation; --yes cannot bypass it."
    confirm "Repair this ONE installation using the external Homebrew method?" || die "Experimental repair canceled."
    return
  fi
  [[ "$VW_YEAR" == "2024" || "$VW_YEAR" == "2026" ]] || return 0
  warn "Vectorworks $VW_YEAR support is EXPERIMENTAL and has not been independently tested."
  warn "The script will continue only if the exact same missing iODBC dependency is present."
  confirm "Continue with the unverified Vectorworks $VW_YEAR repair?" || \
    die "Experimental Vectorworks $VW_YEAR repair was canceled by the user."
}

confirm() {
  local prompt="$1"
  if [[ $ASSUME_YES -eq 1 ]]; then
    return 0
  fi
  [[ -t 0 ]] || die "$prompt Run the script in Terminal or add --yes."
  printf '%s [y/N]: ' "$prompt"
  local answer=""
  read -r answer
  case "$answer" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

check_apple_silicon() {
  local arm_capable translated
  arm_capable="$(/usr/sbin/sysctl -n hw.optional.arm64 2>/dev/null || printf '0')"
  [[ "$arm_capable" == "1" ]] || die "This script supports Apple Silicon Macs only."

  translated="$(/usr/sbin/sysctl -n sysctl.proc_translated 2>/dev/null || printf '0')"
  if [[ "$translated" == "1" ]]; then
    die "Terminal is running through Rosetta. Disable 'Open using Rosetta' and try again."
  fi
  [[ "$(/usr/bin/uname -m)" == "arm64" ]] || die "The current session is not running as arm64."
  ok "Apple Silicon Mac detected (arm64)."
}

check_paths() {
  [[ -d "$VW_ROOT" ]] || die "$VW_ROOT does not exist. Install Vectorworks $VW_YEAR first."
  [[ -d "$VW_APP" ]] || die "The application was not found: $VW_APP"
  [[ -d "$SUPPORT_BUNDLE" ]] || die "The support bundle was not found: $SUPPORT_BUNDLE"
  [[ -f "$SUPPORT_BIN" ]] || die "The Support executable was not found: $SUPPORT_BIN"
  local support_archs
  support_archs="$(/usr/bin/lipo -archs "$SUPPORT_BIN" 2>/dev/null)" || die "Support could not be inspected with lipo."
  [[ " $support_archs " == *" arm64 "* ]] || die "Support does not contain arm64 code: $support_archs"
  ok "Vectorworks $VW_YEAR and Support.vwlibrary were found."
}

has_dependency() {
  local wanted="$1" dependencies
  dependencies="$(/usr/bin/otool -L "$SUPPORT_BIN" 2>/dev/null)" || return 1
  /usr/bin/awk -v wanted="$wanted" '$1 == wanted { found=1 } END { exit !found }' <<< "$dependencies"
}

ensure_brew() {
  if [[ -x "$BREW_BIN" ]]; then
    ok "Homebrew was found at $BREW_BIN."
    return
  fi

  info "Homebrew is not installed in /opt/homebrew."
  confirm "Download and install Homebrew from brew.sh?" || die "Installation was canceled by the user."

  local installer
  installer="$(/usr/bin/mktemp -t install-homebrew.XXXXXX)"
  trap '/bin/rm -f "${installer:-}"; on_exit' EXIT
  /usr/bin/curl --proto '=https' --tlsv1.2 -fsSL \
    "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh" \
    -o "$installer"
  [[ -s "$installer" ]] || die "The downloaded Homebrew installer is empty."

  if [[ $ASSUME_YES -eq 1 ]]; then
    NONINTERACTIVE=1 /bin/bash "$installer"
  else
    /bin/bash "$installer"
  fi
  /bin/rm -f "$installer"
  trap on_exit EXIT
  [[ -x "$BREW_BIN" ]] || die "Homebrew is not available at $BREW_BIN after installation."
  ok "Homebrew was installed successfully."
}

ensure_libiodbc() {
  if [[ ! -f "$NEW_DYLIB" ]]; then
    info "Installing libiodbc with Homebrew..."
    "$BREW_BIN" install libiodbc
  fi
  [[ -f "$NEW_DYLIB" ]] || die "$NEW_DYLIB was not found after installation."

  local dylib_archs dylib_dependencies
  dylib_archs="$(/usr/bin/lipo -archs "$NEW_DYLIB" 2>/dev/null || true)"
  [[ " $dylib_archs " == *" arm64 "* ]] || die "The Homebrew library does not contain arm64 code: $dylib_archs"
  dylib_dependencies="$(/usr/bin/otool -arch arm64 -L "$NEW_DYLIB" 2>/dev/null)" || \
    die "The installed libiodbc could not be inspected with otool."
  /usr/bin/awk 'NR == 2 && /\(compatibility version 4\.0\.0,/ { found=1 } END { exit !found }' \
    <<< "$dylib_dependencies" || \
    die "The installed libiodbc does not declare the ABI compatibility version 4.0.0 required by Vectorworks."
  ok "An arm64-compatible libiodbc is available at $NEW_DYLIB."
}

make_backup() {
  local stamp backup_dir
  stamp="$(/bin/date '+%Y%m%d-%H%M%S')"
  /bin/mkdir -p "$BACKUP_ROOT"
  backup_dir="$(/usr/bin/mktemp -d "$BACKUP_ROOT/$stamp.XXXXXX")"
  /bin/chmod 700 "$BACKUP_ROOT" "$backup_dir"

  /usr/bin/ditto --rsrc --extattr "$SUPPORT_BIN" "$backup_dir/Support.original"
  if [[ $GENERIC_BACKUP -eq 1 ]]; then
    /usr/bin/ditto --rsrc --extattr "$SUPPORT_BUNDLE" "$backup_dir/Support.vwlibrary.original"
    printf '%s\n' "$VW_APP" > "$backup_dir/Application.path"
    (cd "$backup_dir/Support.vwlibrary.original" && /usr/bin/find . -type f -exec /usr/bin/shasum -a 256 {} \;) > "$backup_dir/Bundle.SHA256.txt"
  fi
  if [[ -d "$SUPPORT_BUNDLE/Contents/_CodeSignature" ]]; then
    /usr/bin/ditto --rsrc --extattr \
      "$SUPPORT_BUNDLE/Contents/_CodeSignature" \
      "$backup_dir/_CodeSignature.original"
  fi
  /usr/bin/shasum -a 256 "$backup_dir/Support.original" > "$backup_dir/SHA256.txt"
  {
    printf 'Created: %s\n' "$(/bin/date)"
    printf 'Vectorworks version: %s\n' "$VW_YEAR"
    printf 'Executable: %s\n' "$SUPPORT_BIN"
    printf 'Original dependency: %s\n' "$OLD_DYLIB"
  } > "$backup_dir/README.txt"
  ok "A backup was created at: $backup_dir"
}

sign_and_verify() {
  info "Applying an ad hoc signature to the modified executable..."
  /usr/bin/sudo /usr/bin/codesign --force --sign - "$SUPPORT_BIN"

  if ! /usr/bin/codesign --verify --deep --strict "$SUPPORT_BUNDLE" >/dev/null 2>&1; then
    info "Updating the Support.vwlibrary bundle signature..."
    /usr/bin/sudo /usr/bin/codesign --force --deep --sign - "$SUPPORT_BUNDLE"
  fi

  /usr/bin/codesign --verify --strict --verbose=2 "$SUPPORT_BIN"
  /usr/bin/codesign --verify --deep --strict --verbose=2 "$SUPPORT_BUNDLE"
  ok "The ad hoc signatures are valid."
}

verify_state() {
  check_apple_silicon
  check_macos_version
  check_paths

  local archs
  archs="$(/usr/bin/lipo -archs "$SUPPORT_BIN" 2>/dev/null || true)"
  [[ " $archs " == *" arm64 "* ]] || die "Support does not contain arm64 code: $archs"
  ok "The Support executable contains arm64 code ($archs)."

  if has_dependency "$NEW_DYLIB"; then
    ok "Support points to the Homebrew library."
    [[ -f "$NEW_DYLIB" ]] || die "Support is patched, but the library does not exist: $NEW_DYLIB"
  elif has_dependency "$OLD_DYLIB"; then
    warn "Support still points to $OLD_DYLIB."
    return 2
  else
    die "Support contains neither the original nor the expected dependency. No changes will be made."
  fi

  /usr/bin/codesign --verify --strict --verbose=2 "$SUPPORT_BIN"
  /usr/bin/codesign --verify --deep --strict --verbose=2 "$SUPPORT_BUNDLE"
  ok "Verification completed successfully."
}

repair() {
  check_apple_silicon
  check_macos_version
  check_paths

  if has_dependency "$NEW_DYLIB"; then
    confirm_experimental
    ensure_brew
    ensure_libiodbc
    info "The patch was already present; the executable was not modified."
  elif has_dependency "$OLD_DYLIB"; then
    confirm_experimental
    if [[ $GENERIC_BACKUP -eq 1 ]]; then
      /usr/bin/codesign --verify --deep --strict "$SUPPORT_BUNDLE" || die "The original bundle signature is invalid. Experimental repair stopped before any installation or modification."
    fi
    ensure_brew
    ensure_libiodbc
    make_backup
    info "Changing only the iODBC dependency..."
    /usr/bin/sudo /usr/bin/install_name_tool -change "$OLD_DYLIB" "$NEW_DYLIB" "$SUPPORT_BIN"
    has_dependency "$NEW_DYLIB" || die "The new dependency was not recorded successfully."
  else
    die "The expected dependency was not found in Support. The repair was canceled to prevent damage."
  fi

  sign_and_verify
  /usr/bin/otool -L "$SUPPORT_BIN" | /usr/bin/grep -F "$NEW_DYLIB"
  ok "Vectorworks $VW_YEAR was repaired successfully."

  if [[ $LAUNCH -eq 1 ]]; then
    info "Launching Vectorworks $VW_YEAR..."
    /usr/bin/open "$VW_APP"
  fi
}

latest_backup() {
  [[ -d "$BACKUP_ROOT" ]] || return 1
  /usr/bin/find "$BACKUP_ROOT" -mindepth 2 -maxdepth 2 -type f \
    -name 'Support.original' -print 2>/dev/null | /usr/bin/sort | /usr/bin/tail -n 1
}

list_backups_for_year() {
  local year="$1" root item found=0
  root="$HOME/Library/Application Support/Vectorworks $year iODBC Fix/backups"
  [[ -d "$root" ]] || return 1
  while IFS= read -r item; do
    [[ -n "$item" ]] || continue
    printf 'Vectorworks %s: %s\n' "$year" "${item%/Support.original}"
    found=1
  done < <(/usr/bin/find "$root" -mindepth 2 -maxdepth 2 -type f \
    -name 'Support.original' -print 2>/dev/null | /usr/bin/sort)
  [[ $found -eq 1 ]]
}

list_backups() {
  local found=0 year
  for year in "${SUPPORTED_YEARS[@]}"; do
    if list_backups_for_year "$year"; then found=1; fi
  done
  [[ $found -eq 1 ]] || info "No backups are available."
}

rollback() {
  check_apple_silicon
  check_macos_version
  check_paths

  local backup_file backup_dir
  backup_file="$(latest_backup || true)"
  [[ -n "$backup_file" && -f "$backup_file" ]] || die "No backup is available to restore."
  backup_dir="${backup_file%/Support.original}"
  if [[ $EXPERIMENTAL -eq 1 ]]; then
    [[ $ASSUME_YES -eq 0 ]] || die "Experimental rollback requires interactive confirmation."
    if [[ $GENERIC_BACKUP -eq 1 ]]; then
      [[ -f "$backup_dir/Application.path" && "$(< "$backup_dir/Application.path")" == "$VW_APP" ]] || die "Backup belongs to another installation."
      [[ -d "$backup_dir/Support.vwlibrary.original" && -f "$backup_dir/Bundle.SHA256.txt" ]] || die "Complete experimental backup is missing."
      (cd "$backup_dir/Support.vwlibrary.original" && /usr/bin/shasum -a 256 -c "$backup_dir/Bundle.SHA256.txt") || die "Bundle backup checksum verification failed. Nothing was restored."
    fi
  fi

  info "The following backup will be restored: $backup_dir"
  confirm "Restore the most recent original Support executable?" || die "Rollback was canceled by the user."

  /usr/bin/shasum -a 256 -c "$backup_dir/SHA256.txt" || die "Executable backup checksum verification failed. Nothing was restored."
  if [[ $GENERIC_BACKUP -eq 1 ]]; then
    # Preserve the current component outside the installation before replacing it.
    local restore_dir displaced
    restore_dir="$(/usr/bin/mktemp -d "$BACKUP_ROOT/restore.XXXXXX")"
    /usr/bin/ditto --rsrc --extattr "$backup_dir/Support.vwlibrary.original" "$restore_dir/Support.prepared" || die "Could not prepare restoration; installed bundle is unchanged."
    (cd "$restore_dir/Support.prepared" && /usr/bin/shasum -a 256 -c "$backup_dir/Bundle.SHA256.txt") || die "Prepared bundle checksum failed; installed bundle is unchanged."
    /usr/bin/codesign --verify --deep --strict "$restore_dir/Support.prepared" || die "Prepared bundle signature failed; installed bundle is unchanged."
    displaced="$restore_dir/Support.displaced"
    /usr/bin/sudo /bin/mv "$SUPPORT_BUNDLE" "$displaced" || die "Could not preserve installed bundle. Restoration stopped."
    if ! /usr/bin/sudo /bin/mv "$restore_dir/Support.prepared" "$SUPPORT_BUNDLE"; then
      if [[ ! -e "$SUPPORT_BUNDLE" ]]; then
        /usr/bin/sudo /bin/mv "$displaced" "$SUPPORT_BUNDLE" || warn "Automatic recovery failed; previous bundle: $displaced"
      fi
      die "Restoration could not be completed. Check the installation before launching; recovery files: $restore_dir"
    fi
    info "The pre-rollback bundle is preserved at: $displaced"
  else
    /usr/bin/sudo /usr/bin/ditto --rsrc --extattr "$backup_file" "$SUPPORT_BIN"
  fi

  if [[ $GENERIC_BACKUP -eq 1 ]]; then
    : # Full bundle restoration already restores its original signatures.
  elif [[ -d "$backup_dir/_CodeSignature.original" ]]; then
    /usr/bin/sudo /bin/rm -rf "$SUPPORT_BUNDLE/Contents/_CodeSignature"
    /usr/bin/sudo /usr/bin/ditto --rsrc --extattr \
      "$backup_dir/_CodeSignature.original" \
      "$SUPPORT_BUNDLE/Contents/_CodeSignature"
  else
    warn "The backup does not contain the original outer signature; a functional ad hoc signature will be applied."
    /usr/bin/sudo /usr/bin/codesign --force --deep --sign - "$SUPPORT_BUNDLE"
  fi

  has_dependency "$OLD_DYLIB" || die "The restored file does not contain the original dependency."
  /usr/bin/codesign --verify --deep --strict --verbose=2 "$SUPPORT_BUNDLE"
  ok "Rollback completed. Support points to $OLD_DYLIB again."
  warn "On macOS 27, Vectorworks will probably fail to launch while using this missing path."
}

if [[ $SCAN -eq 1 ]]; then
  [[ -z "$APP_SELECTION" ]] || die "--scan lists installations; omit --app."
  check_apple_silicon
  check_macos_version
  discover_experimental
  info "Read-only scan completed. Candidates are not certified compatible. No changes were made."
elif [[ "$MODE" == "list" && $EXPERIMENTAL -eq 1 ]]; then
  select_experimental
  if [[ -d "$BACKUP_ROOT" ]]; then
    /usr/bin/find "$BACKUP_ROOT" -mindepth 2 -maxdepth 2 -name Support.original -print
  else
    info "No backups are available for this installation."
  fi
elif [[ "$MODE" == "list" ]]; then
  list_backups
else
  if [[ $EXPERIMENTAL -eq 1 ]]; then select_experimental; else select_version; fi
  case "$MODE" in
    repair) repair ;;
    verify) verify_state ;;
    rollback) rollback ;;
  esac
fi
