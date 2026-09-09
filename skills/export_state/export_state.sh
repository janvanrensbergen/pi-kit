#!/usr/bin/env bash
set -euo pipefail
# export_state.sh
# Exports OMP and optionally pi session/memory directories into a timestamped tarball in a target output directory (default: repo root / pwd).

usage(){
  cat <<EOF
Usage: $0 [--out-dir PATH] [--include-pi] [--encrypt RECIPIENT|--symmetric]

--out-dir PATH    Directory where the tarball will be written (default: current working directory)
--include-pi      Also attempt to include /home/pi common locations (best-effort)
--encrypt ARG     If ARG is "--symmetric" the script will prompt for a passphrase and produce .gpg. Otherwise treat ARG as GPG recipient (public key id/email)

Examples:
  $0
  $0 --out-dir /host-mount --include-pi
  $0 --encrypt alice@example.com
  $0 --encrypt --symmetric
EOF
}

OUT_DIR="$(pwd)"
INCLUDE_PI=0
ENCRYPT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out-dir)
      shift; OUT_DIR="$1"; shift;;
    --include-pi)
      INCLUDE_PI=1; shift;;
    --encrypt)
      shift; if [[ "$1" == "--symmetric" ]]; then ENCRYPT="--symmetric"; else ENCRYPT="$1"; fi; shift;;
    -h|--help)
      usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 2;;
  esac
done

mkdir -p "$OUT_DIR"
TS=$(date +%F_%H%M%S)
NAME="omp-backup-${TS}.tar.gz"
ARCHIVE="$OUT_DIR/$NAME"

# Candidates to include (path -> label)
declare -A CANDIDATES
CANDIDATES["$HOME/.omp/agent/sessions"]="omp_sessions"
CANDIDATES["$HOME/.omp/agent/projects-memory"]="omp_projects_memory"

if [[ $INCLUDE_PI -eq 1 ]]; then
  # Best-effort common pi locations
  CANDIDATES["/home/pi/.omp/agent/sessions"]="pi_omp_sessions"
  CANDIDATES["/home/pi/.omp/agent/projects-memory"]="pi_projects_memory"
  CANDIDATES["/home/pi/.local/share/pi-memory"]="pi_local_memory"
fi

# Build tar args: only include existing paths
TMPFILE_LIST=$(mktemp)
trap 'rm -f "$TMPFILE_LIST"' EXIT

for p in "${!CANDIDATES[@]}"; do
  if [[ -e "$p" ]]; then
    echo "$p" >> "$TMPFILE_LIST"
  fi
done

if [[ ! -s "$TMPFILE_LIST" ]]; then
  echo "No known OMP/pi state directories found to archive. Checked:" >&2
  for p in "${!CANDIDATES[@]}"; do echo "  - $p"; done
  exit 1
fi

# Try to stop OMP if running (best-effort)
if command -v omp >/dev/null 2>&1; then
  echo "Attempting to ask OMP to stop agents (best-effort)..."
  if omp status >/dev/null 2>&1; then
    if command -v systemctl >/dev/null 2>&1; then
      echo "No systemctl-managed OMP detected in sbx. Skipping service stop." 
    fi
    # We won't force-stop; users should stop OMP manually if they want atomic snapshot
  fi
fi

# Create tar preserving ownership
# Use --files-from to avoid weird path prefixes; store relative paths with leading dot
pushd / >/dev/null
# Create a temporary directory tree that mirrors the paths to get deterministic archive layout
WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

while read -r src; do
  if [[ -e "$src" ]]; then
    # create parent dir inside workdir and bind-copy
    rel=$(realpath --relative-to=/ "$src")
    destdir="$WORKDIR/$(dirname "$rel")"
    mkdir -p "$destdir"
    # copy preserving attributes
    cp -a "$src" "$destdir/"
  fi
done < "$TMPFILE_LIST"

pushd "$WORKDIR" >/dev/null
# Make archive
tar --numeric-owner -czf "$ARCHIVE" .
popd >/dev/null
popd >/dev/null

echo "Created archive: $ARCHIVE"
sha256sum "$ARCHIVE" > "$ARCHIVE.sha256"

# Print counts per archived path
echo "Contents summary:" 
tar -tf "$ARCHIVE" | sed -n '1,20p'

# Optional encryption
if [[ -n "$ENCRYPT" ]]; then
  if [[ "$ENCRYPT" == "--symmetric" ]]; then
    echo "Encrypting symmetrically (passphrase will be prompted)."
    gpg --symmetric --cipher-algo AES256 --output "$ARCHIVE.gpg" "$ARCHIVE"
  else
    echo "Encrypting to recipient: $ENCRYPT"
    gpg --output "$ARCHIVE.gpg" --encrypt --recipient "$ENCRYPT" "$ARCHIVE"
  fi
  echo "Encrypted archive: $ARCHIVE.gpg"
  sha256sum "$ARCHIVE.gpg" > "$ARCHIVE.gpg.sha256"
fi

# Final verification: list archived top-level entries
echo "Top-level entries in archive:"
tar -tzf "$ARCHIVE" | awk -F"/" '{print $1"/"}' | sort -u | while read l; do echo "  $l"; done

echo "Done. Move the archive from $OUT_DIR to your host or a safe place."
exit 0
