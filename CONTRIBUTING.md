# Contributing

Thank you for helping validate and improve this workaround.

## Test reports

Use the provided test-report issue template. Vectorworks 2026 reports are especially useful because support for that version is currently experimental and unverified.

Do not publish proprietary Vectorworks binaries or license information. This repository accepts only original scripts, documentation, diagnostic excerpts, and reproducible test results.

## Pull requests

Keep changes narrowly scoped. Shell changes should:

- Remain compatible with the Bash version included with macOS.
- Preserve `set -euo pipefail`.
- Avoid disabling SIP or writing to protected system locations.
- Preserve exact dependency checks and rollback support.
- Pass `bash -n Fix-Vectorworks-iODBC.command`.
- Include corresponding documentation and changelog updates.

By contributing, you agree that your contribution may be distributed under the MIT License.

