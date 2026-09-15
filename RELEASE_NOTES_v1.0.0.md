# Fix Vectorworks 2025/2026 Not Launching on macOS 27 — v1.0.0

Initial public release of the unofficial, reversible community workaround created by **Wagner R. Ponce of ANIFONIX**.

## Compatibility

- **Vectorworks 2025 Update 8:** tested on Apple Silicon with macOS 27.0.
- **Vectorworks 2026:** experimental and not yet independently verified.

## Included safeguards

- Exact missing-dependency detection before modification
- Apple Silicon, native arm64, and macOS 27 checks
- Homebrew installation confirmation
- `libiodbc` architecture and ABI validation
- External backup with SHA-256 checksum
- Code-signing verification
- Already-patched detection
- Version-specific rollback
- No SIP changes and no modifications to `/usr/lib`

Read the README and security guidance before running the script. Vectorworks 2026 testers are encouraged to submit a compatibility test report through GitHub Issues.
