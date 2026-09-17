# Changelog

All notable changes to this project will be documented here.

## Unreleased

- Added opt-in `--experimental` dependency-based discovery for other standard Vectorworks YEAR.app installations, without expanding default version selection.
- Added read-only `--experimental --scan` and explicit `--app PATH` selection; no batch repair and no unattended experimental repair/rollback.
- Require arm64 in both application and Support, exact original/Homebrew arm64 dependency and required compatibility 4.0.0; reject loader-relative patches and symbolic-link layouts.
- Preserve existing 2024/2025/2026 backup namespaces; other installations use path-hashed namespaces with complete Support bundle backups and restoration.
- Added generated Mach-O fixture tests for discovery and complete backup/rollback, not real application compatibility tests.
- Documented Mike Hayes's manual 2022 SP6 success separately from this unverified external-library mode.
- Added experimental, unverified Vectorworks 2024 selection, detection, external backups, verification and rollback.
- Generalized installed-version selection and backup listing for 2024, 2025 and 2026.
- Require arm64 code in Support before repair as well as verification and rollback.

- Fixed false dependency-detection failures on Universal Binary installations caused by `grep -q` interacting with `set -o pipefail`.
- Applied the same pipe-safe check to the Homebrew `libiodbc` ABI validation.
- Thanks to GitHub user `@lahmadinia` for reporting and diagnosing the Universal Binary detection issue.

## 1.0.0 — 2026-09-14

- Added tested support for Vectorworks 2025 Update 8 on macOS 27 and Apple Silicon.
- Added experimental, unverified handling for Vectorworks 2026.
- Added automatic installed-version detection and explicit `--version` selection.
- Added Homebrew and `libiodbc` installation checks.
- Added exact dependency, architecture, and ABI compatibility checks.
- Added external backups, SHA-256 validation, code-signing verification, and rollback.
- Added English and Spanish documentation.
