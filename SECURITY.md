# Security and privacy

## Scope

This script modifies a vendor-signed executable inside a Vectorworks installation. It should be used only when the affected `Support` executable contains the exact missing dependency documented in the README.

## Safety properties

- The script does not disable System Integrity Protection.
- It does not create or modify files in `/usr/lib`.
- It refuses unsupported Vectorworks versions and operating-system versions.
- It saves the original executable outside the application bundle before patching.
- It validates the backup checksum before rollback.
- It downloads the Homebrew installer only from Homebrew's official GitHub repository over HTTPS, and only after user confirmation unless `--yes` is supplied.
- If Gatekeeper blocks the downloaded script, verify its published SHA-256 before removing `com.apple.quarantine`, and remove that attribute from the script only. Do not clear quarantine recursively from broad directories.

## Reporting a vulnerability

Open a GitHub issue containing a minimal reproduction and no secrets. If public disclosure would place users at risk, contact the repository owner privately through the contact method shown on their GitHub profile before publishing technical details.

## Privacy

Before attaching Terminal output or a macOS crash report, remove:

- Vectorworks serial numbers
- Crash Reporter Keys
- Incident Identifiers
- Usernames and personal file paths
- Email addresses
- Passwords, API keys, tokens, and credentials
