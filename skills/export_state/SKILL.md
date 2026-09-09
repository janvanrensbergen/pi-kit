---
name: export_state
description: Export OMP/pi sessions and memory to a tarball in repo root
---

Purpose: Export OMP and pi sessions and project-memory to a tarball placed in the repository root. Intended to run inside the sandbox (sbx). The script discovers OMP paths and optionally pi user paths and creates a timestamped tar.gz in the repo root.

Usage:
./export_state.sh [--out-dir /path/to/out] [--include-pi] [--encrypt <gpg-recipient|--symmetric>]

Behavior:
- Default out dir: repository root (project working directory). Uses $PWD if run from repo root.
- Archives: ~/.omp/agent/sessions and ~/.omp/agent/projects-memory (if present).
- If --include-pi provided, also archives /home/pi/.omp (if present) and /home/pi/.local/share/pi-memory (best-effort).
- Produces: omp-backup-YYYYMMDD_HHMMSS.tar.gz (and .sha256). If encrypting with GPG, produces .tar.gz.gpg instead.
- Verifies created tar by listing contents and printing counts.

Notes:
- Run from inside sbx; ensure the out dir is writable and mounted to host if you want to persist outside the container.
- Preserve UID/GID in tar so restore can chown appropriately on extraction.
- Stops OMP agents if possible (best-effort) to reduce risk of partial writes; warns if cannot stop.

Security:
- If you use --encrypt, keep keys safe. Symmetric passphrases are not stored by the script.

Checks performed after creation:
- sha256 checksum written to <archive>.sha256
- prints number of files archived per included path
