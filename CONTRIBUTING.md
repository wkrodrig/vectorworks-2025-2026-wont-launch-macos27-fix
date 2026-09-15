# Contributing

Contributions must not include proprietary Vectorworks binaries, license information, serial numbers, credentials, or unredacted crash data.

## Pull requests

Keep changes narrowly scoped. Shell changes should:

- Remain compatible with the Bash version included with macOS.
- Preserve `set -euo pipefail`.
- Avoid disabling SIP or writing to protected system locations.
- Preserve exact dependency checks and rollback support.
- Pass `bash -n Fix-Vectorworks-iODBC.command`.
- Include corresponding documentation and changelog updates.

By contributing, you agree that your contribution may be distributed under the MIT License.
