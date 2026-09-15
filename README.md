# Fix Vectorworks 2025/2026 Not Launching on macOS 27

[Leer en español](README.es.md)

An unofficial, reversible community workaround for the **“Failure loading Support Library”** error that prevents Vectorworks 2025 or 2026 from launching on Apple Silicon Macs running macOS 27. The failure occurs when `Support.vwlibrary` depends on the missing system path `/usr/lib/libiodbc.2.dylib`.

Created by **Wagner R. Ponce — ANIFONIX**.

> [!IMPORTANT]
> This project is not affiliated with, endorsed by, or supported by Vectorworks, Inc., Nemetschek, Apple, or Homebrew. It modifies a vendor-signed Vectorworks component. Review the script, keep a backup, and use it at your own risk.

## Compatibility status

| Vectorworks version | Status | Notes |
|---|---|---|
| Vectorworks 2025 Update 8 | Tested | Confirmed working on an Apple Silicon Mac with macOS 27.0. |
| Vectorworks 2026 | Experimental | A similar “Failure loading Support Library” problem has been reported, but this repair has not yet been independently tested on 2026. |

The script refuses to patch either version unless it finds the exact dependency:

```text
/usr/lib/libiodbc.2.dylib
```

## Symptoms

Vectorworks quits during startup and may display:

```text
Failure loading Support Library
```

Starting the application from Terminal may reveal:

```text
Library not loaded: /usr/lib/libiodbc.2.dylib
Referenced from: .../Plug-ins/Support.vwlibrary/Contents/MacOS/Support
```

Do not use this workaround for an unrelated crash or a different missing library.

## What the script does

The script:

- Requires macOS 27 and an Apple Silicon Mac running natively as `arm64`.
- Detects Vectorworks 2025 or 2026 in `/Applications`.
- Lets you select a version when both are installed.
- Marks Vectorworks 2026 support as experimental and requests an additional confirmation.
- Checks for Homebrew and asks permission before installing it.
- Installs the Homebrew `libiodbc` formula when required.
- Confirms that the installed library contains `arm64` code and declares compatibility version `4.0.0`.
- Saves the original `Support` executable outside the Vectorworks bundle.
- Saves the original outer code signature when available.
- Changes the Mach-O dependency to `/opt/homebrew/opt/libiodbc/lib/libiodbc.2.dylib`.
- Applies an ad hoc signature and verifies the modified executable and bundle.
- Detects an already-patched installation.
- Provides verification, backup listing, and rollback modes.

It does **not** disable System Integrity Protection and does **not** create or modify files in `/usr/lib`.

## Requirements

- Apple Silicon Mac
- macOS 27
- Vectorworks 2025 or 2026 installed in its standard `/Applications` location
- Administrator access
- Internet access if Homebrew or `libiodbc` must be installed

## Installation and normal use

1. Download `Fix-Vectorworks-iODBC.command` from this repository or the latest release.
2. Open Terminal in the download directory.
3. Make it executable:

   ```bash
   chmod +x Fix-Vectorworks-iODBC.command
   ```

4. Run it:

   ```bash
   ./Fix-Vectorworks-iODBC.command
   ```

You can subsequently open it by double-clicking. If macOS blocks the first launch, Control-click the file, choose **Open**, and confirm.

The script may request your administrator password. Characters are not displayed while typing a password in Terminal; this is normal.

## Command-line options

```text
--repair         Repair Vectorworks (default action).
--verify         Check the current status without modifying anything.
--rollback       Restore the most recent backup.
--list-backups   List available backups.
--version YEAR   Select Vectorworks 2025 or 2026.
--yes, -y        Automatically approve required installations.
--no-launch      Do not launch Vectorworks when finished.
--help, -h       Display help.
```

Examples:

```bash
# Repair the only supported version found in /Applications
./Fix-Vectorworks-iODBC.command

# Explicitly repair Vectorworks 2025 without launching it afterward
./Fix-Vectorworks-iODBC.command --version 2025 --no-launch

# Experimental, unverified Vectorworks 2026 path
./Fix-Vectorworks-iODBC.command --version 2026

# Verify Vectorworks 2025 without modifying it
./Fix-Vectorworks-iODBC.command --verify --version 2025

# List backups for both versions
./Fix-Vectorworks-iODBC.command --list-backups

# Restore the latest Vectorworks 2025 backup
./Fix-Vectorworks-iODBC.command --rollback --version 2025
```

## Backups and rollback

Backups are kept outside the application bundle:

```text
~/Library/Application Support/Vectorworks 2025 iODBC Fix/backups
~/Library/Application Support/Vectorworks 2026 iODBC Fix/backups
```

Each backup includes the original executable, its SHA-256 checksum, metadata, and the original outer signature when available.

To restore the latest backup:

```bash
./Fix-Vectorworks-iODBC.command --rollback --version 2025
```

On macOS 27, restoring the original dependency will probably restore the original launch failure as well.

## Manual diagnosis

For Vectorworks 2025:

```bash
otool -L "/Applications/Vectorworks 2025/Plug-ins/Support.vwlibrary/Contents/MacOS/Support" | grep -i iodbc
```

For Vectorworks 2026:

```bash
otool -L "/Applications/Vectorworks 2026/Plug-ins/Support.vwlibrary/Contents/MacOS/Support" | grep -i iodbc
```

An affected, unpatched binary reports `/usr/lib/libiodbc.2.dylib`. A successfully patched binary reports `/opt/homebrew/opt/libiodbc/lib/libiodbc.2.dylib`.

## Limitations

- Modifying the executable invalidates the vendor signature, so the script replaces it with an ad hoc signature.
- A Vectorworks update, repair, or reinstallation can overwrite the patch.
- A future Homebrew update could change library compatibility. The script checks the required architecture and compatibility version before patching.
- Vectorworks 2026 support is experimental until users confirm the dependency, successful startup, signing, and rollback on a real installation.
- The preferred long-term solution is an official Vectorworks update built for macOS 27.

## Reporting results

Use the GitHub issue templates and include:

- Mac model and processor
- Exact macOS version and build
- Vectorworks edition, version, and update number
- Clean installation or operating-system upgrade
- The iODBC line produced by `otool -L`
- Whether repair, launch, verification, and rollback succeeded

Never publish your Vectorworks serial number, Crash Reporter Key, Incident Identifier, passwords, tokens, or other personal information.

## Project files

- `Fix-Vectorworks-iODBC.command` — standalone repair and rollback script
- `README.md` — English documentation
- `README.es.md` — Spanish documentation
- `CHANGELOG.md` — release history
- `SECURITY.md` — security and privacy guidance
- `CONTRIBUTING.md` — contribution instructions
- `LICENSE` — MIT License
- `SHA256SUMS.txt` — release file checksums

## References

- [Vectorworks macOS 27 compatibility notice](https://www.vectorworks.co.jp/Support/tips/os_products_goldengate.html)
- [Homebrew libiodbc formula](https://formulae.brew.sh/formula/libiodbc.html)
- [Apple: Dynamic Library Identification](https://developer.apple.com/forums/thread/736719)
- [Apple DTS: modified signed code must be re-signed](https://developer.apple.com/forums/thread/670761)

## Author

**Wagner R. Ponce**  
**ANIFONIX**

## License

Released under the [MIT License](LICENSE).
