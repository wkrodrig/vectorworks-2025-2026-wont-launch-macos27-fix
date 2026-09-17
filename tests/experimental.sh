#!/bin/bash
# macOS arm64 fixture tests: no installed apps, Homebrew, sudo or repairs.
set -euo pipefail
cd "$(dirname "$0")/.."
test_root="$(/usr/bin/mktemp -d /tmp/vectorworks-fixtures.XXXXXX)"
trap '/bin/rm -rf "$test_root"' EXIT
mkdir -p "$test_root/Applications" "$test_root/backups"
readonly OLD_DYLIB=/usr/lib/libiodbc.2.dylib
readonly NEW_DYLIB=/opt/homebrew/opt/libiodbc/lib/libiodbc.2.dylib
EXPERIMENTAL=1
ASSUME_YES=0
GENERIC_BACKUP=0
APP_SELECTION=""
VW_YEAR=""
die() { printf '%s\n' "$*" >&2; exit 1; }
ok() { :; }
info() { :; }
warn() { :; }
eval "$(/usr/bin/awk -v root="$test_root/Applications" '
  /^(configure_app|dependency_version|experimental_candidate|discover_experimental|select_experimental|confirm_experimental|check_paths|has_dependency|make_backup|latest_backup|rollback|repair|sign_and_verify)\(\) [{]/ { copying=1 }
  copying { gsub("/Applications", root); gsub("/usr/bin/sudo", "fixture_sudo"); print }
  copying && /^[}]/ { copying=0 }
' Fix-Vectorworks-iODBC.command)"
fixture_sudo() { "$@"; } # All paths used below belong to test_root.
check_apple_silicon() { :; }
check_macos_version() { :; }
confirm() { return 0; }
ensure_brew() { :; } # Never install or invoke Homebrew in tests.
ensure_libiodbc() { :; } # The generated library is only a load-reference fixture.
LAUNCH=0
app22="$test_root/Applications/Vectorworks 2022/Vectorworks 2022.app"
app23="$test_root/Applications/Vectorworks 2023/Vectorworks 2023.app"
app25="$test_root/Applications/Vectorworks 2025/Vectorworks 2025.app"
clang -arch arm64 tests/fixtures/main.c -o "$test_root/Vectorworks"
for app in "$app22" "$app23" "$app25"; do
  mkdir -p "$app/Contents/MacOS" "${app%/*}/Plug-Ins/Support.vwlibrary/Contents/MacOS"
  cp tests/fixtures/Info.plist "$app/Contents/Info.plist"
  cp "$test_root/Vectorworks" "$app/Contents/MacOS/Vectorworks"
  cp tests/fixtures/Support.plist "${app%/*}/Plug-Ins/Support.vwlibrary/Contents/Info.plist"
done
clang -arch arm64 -dynamiclib tests/fixtures/library.c -Wl,-install_name,"$OLD_DYLIB" -Wl,-compatibility_version,4.0.0 -o "$test_root/libiodbc.dylib"
clang -arch arm64 -bundle tests/fixtures/support.c "$test_root/libiodbc.dylib" -o "$test_root/Support"
for app in "$app22" "$app23" "$app25"; do
  cp "$test_root/Support" "${app%/*}/Plug-Ins/Support.vwlibrary/Contents/MacOS/Support"
done
experimental_candidate "$app22"
[[ "$(dependency_version "$OLD_DYLIB")" == 4.0.0 && $GENERIC_BACKUP -eq 1 ]]
if has_dependency /usr/lib/libiodbc; then die 'Accepted a dependency substring'; fi
backup22="$BACKUP_ROOT"
experimental_candidate "$app23"
[[ "$BACKUP_ROOT" != "$backup22" ]]
experimental_candidate "$app25"
[[ $GENERIC_BACKUP -eq 0 && "$BACKUP_ROOT" == "$HOME/Library/Application Support/Vectorworks 2025 iODBC Fix/backups" ]]
experimental_candidate "$app22"
APP_SELECTION="$app22"
select_experimental
APP_SELECTION=""
if (select_experimental) </dev/null >/dev/null 2>&1; then die 'Unattended discovery selected an app'; fi
ASSUME_YES=1
if (confirm_experimental) >/dev/null 2>&1; then die 'Experimental confirmation was bypassed'; fi
ASSUME_YES=0
clang -arch x86_64 -dynamiclib tests/fixtures/library.c -Wl,-install_name,"$OLD_DYLIB" -Wl,-compatibility_version,4.0.0 -o "$test_root/intel-library.dylib"
clang -arch x86_64 -bundle tests/fixtures/support.c "$test_root/intel-library.dylib" -o "${app23%/*}/Plug-Ins/Support.vwlibrary/Contents/MacOS/Support"
if (experimental_candidate "$app23") >/dev/null 2>&1; then die 'Accepted Intel-only Support'; fi
cp "$test_root/Support" "${app23%/*}/Plug-Ins/Support.vwlibrary/Contents/MacOS/Support"
cp "$test_root/Support" "$app23/Contents/MacOS/Vectorworks"
install_name_tool -change "$OLD_DYLIB" "$OLD_DYLIB.extra" "${app23%/*}/Plug-Ins/Support.vwlibrary/Contents/MacOS/Support"
if (experimental_candidate "$app23") >/dev/null 2>&1; then die 'Accepted a dependency prefix'; fi
cp "$test_root/Support" "${app23%/*}/Plug-Ins/Support.vwlibrary/Contents/MacOS/Support"
install_name_tool -change "$OLD_DYLIB" @loader_path/libiodbc.2.dylib "${app23%/*}/Plug-Ins/Support.vwlibrary/Contents/MacOS/Support"
if (experimental_candidate "$app23") >/dev/null 2>&1; then die 'Accepted a loader-relative patch'; fi
discover_experimental >/dev/null
[[ ${#CANDIDATES[@]} -eq 2 ]]
ln -s "$app22" "$test_root/Applications/Vectorworks 2022/Vectorworks 2099.app"
if (configure_app "$test_root/Applications/Vectorworks 2022/Vectorworks 2099.app") >/dev/null 2>&1; then die 'Accepted a symlink'; fi
if (configure_app "$test_root/Applications/Vectorworks 2022/Vectorworks Updater.app") >/dev/null 2>&1; then die 'Accepted updater'; fi
# Complete backup/rollback test on a generated component, never vendor code.
experimental_candidate "$app22"
BACKUP_ROOT="$test_root/backups"
codesign --force --sign - "$SUPPORT_BUNDLE"
make_backup
make_backup # No collision even within the same second.
[[ $(find "$BACKUP_ROOT" -name Support.original | wc -l) -eq 2 ]]
repair
has_dependency "$NEW_DYLIB"
count="$(find "$BACKUP_ROOT" -name Support.original | wc -l)"
repair # Already-patched detection must not create another original backup.
[[ "$(find "$BACKUP_ROOT" -name Support.original | wc -l)" -eq $count ]]
rollback
has_dependency "$OLD_DYLIB"
cmp "$(latest_backup)" "$SUPPORT_BIN"
before="$(shasum -a 256 "$SUPPORT_BIN")"
cp "$test_root/libiodbc.dylib" "$(latest_backup)"
if (rollback) >/dev/null 2>&1; then die 'Restored a corrupted backup'; fi
[[ "$(shasum -a 256 "$SUPPORT_BIN")" == "$before" ]]
printf 'PASS: experimental discovery, exact arm64 dependency, selection, backup isolation and full fixture rollback\n'
