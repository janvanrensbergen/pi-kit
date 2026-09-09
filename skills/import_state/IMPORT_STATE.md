Purpose: Import an exported tarball produced by export_state.sh. Restores OMP and pi session/memory directories, preserves ownership where possible, and provides safety checks.

Usage:
  ./import_state.sh /path/to/omp-backup-YYYYMMDD_HHMMSS.tar.gz [--target-home /home/user] [--chown-to CURRENT_UID]

Behavior:
  - Default target home: current user's HOME.
  - The script extracts into / (root) using a temporary extraction dir, then copies files to their final locations.
  - It will not overwrite existing directories unless --force is supplied.
  - After extraction, it prints instructions to chown files to desired UID:GID if needed.

Security:
  - If archive is encrypted (.gpg), the script will attempt gpg --decrypt and extract the result.

Checks performed:
  - verifies sha256 if a .sha256 file exists alongside the archive.
  - lists top-level paths to be restored and prompts for confirmation (unless --yes supplied).
