# GitHub publishing checklist

## Suggested repository settings

- **Repository name:** `vectorworks-2025-2026-wont-launch-macos27-fix`
- **Description:** `Fixes “Failure loading Support Library” preventing Vectorworks 2025/2026 from launching on macOS 27 Apple Silicon.`
- **Visibility:** Public
- **License:** MIT
- **Default branch:** `main`
- **Issues:** Enabled
- **Discussions:** Optional

Suggested topics:

```text
vectorworks macos macos27 apple-silicon iodbc homebrew workaround shell-script
```

## Before uploading

1. Read `README.md`, `SECURITY.md`, and `LICENSE`.
2. Confirm that `Fix-Vectorworks-iODBC.command` is executable.
3. Run:

   ```bash
   bash -n Fix-Vectorworks-iODBC.command
   ./Fix-Vectorworks-iODBC.command --help
   shasum -a 256 -c SHA256SUMS.txt
   ```

4. Do not add crash reports, Vectorworks executables, serial numbers, or personal information.

## Upload through the GitHub website

1. Create a new public repository named `vectorworks-2025-2026-wont-launch-macos27-fix`.
2. Do not initialize it with another README or license.
3. Upload the complete contents of this folder, including `.github`, `.gitattributes`, and `.gitignore`.
4. Commit with a message such as `Initial public release v1.0.0`.
5. Add the suggested description and topics.
6. Enable Issues so users can submit the included compatibility test form.

## First release

Create a release with:

- **Tag:** `v1.0.0`
- **Title:** `Fix Vectorworks 2025/2026 Not Launching on macOS 27 — v1.0.0`
- **Release notes:** Copy `RELEASE_NOTES_v1.0.0.md`.
- **Assets:** `Fix-Vectorworks-iODBC.command` and `SHA256SUMS.txt`.

Mark the release as a normal release, not a pre-release. The project as a whole is usable for the tested Vectorworks 2025 path; the documentation separately marks Vectorworks 2026 support as experimental.

## Suggested forum link text

```text
The source code, safety checks, rollback instructions, and current releases are available on GitHub:
[INSERT REPOSITORY URL]

This is an unofficial community workaround created by Wagner R. Ponce of ANIFONIX. Vectorworks 2025 Update 8 has been tested; Vectorworks 2026 support remains experimental and unverified.
```
