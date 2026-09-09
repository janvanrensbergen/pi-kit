#!/usr/bin/env bash
set -euo pipefail
# import_state.sh
# Restores an archive created by export_state.sh. Run inside sbx. Does NOT automatically overwrite existing data without --force.

usage(){
  cat <<EOF
Usage: $0 <archive.tar.gz|archive.tar.gz.gpg> [--target-home /home/user] [--force] [--yes]

Options:
  --target-home PATH   Treat PATH as the home directory root for restoration (default: current HOME)
  --force              Overwrite existing target dirs without prompt
  --yes                Skip confirmation prompts

Examples:
  $0 /host-mount/omp-backup-2026-09-09_123000.tar.gz
  $0 /host-mount/omp-backup-...tar.gz.gpg --target-home /home/pi --force
EOF
}

ARCHIVE=""
TARGET_HOME="$HOME"
FORCE=0
ASSUME_YES=0

if [[ $# -lt 1 ]]; then usage; exit 2; fi
ARCHIVE="$1"; shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target-home) shift; TARGET_HOME="$1"; shift;;
    --force) FORCE=1; shift;;
    --yes) ASSUME_YES=1; shift;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg $1"; usage; exit 2;;
  esac
done

if [[ ! -f "$ARCHIVE" ]]; then echo "Archive not found: $ARCHIVE" >&2; exit 3; fi

# If encrypted
if [[ "$ARCHIVE" == *.gpg ]]; then
  echo "Detected .gpg; will attempt to decrypt to a temp tar.gz"
  TMP_OUT=$(mktemp -u --suffix=.tar.gz)
  gpg --output "$TMP_OUT" --decrypt "$ARCHIVE"
  ARCHIVE="$TMP_OUT"
fi

# If there's a checksum file, verify it
if [[ -f "$ARCHIVE.sha256" ]]; then
  echo "Verifying sha256..."
  (cd $(dirname "$ARCHIVE") && sha256sum -c "$(basename "$ARCHIVE").sha256")
fi

# List top-level entries
echo "Archive top-level entries:"
tar -tzf "$ARCHIVE" | awk -F"/" '{print $1"/"}' | sort -u | while read l; do echo "  $l"; done

if [[ $ASSUME_YES -ne 1 ]]; then
  if [[ $FORCE -eq 0 ]]; then
    read -p "Proceed with restore to target home '$TARGET_HOME'? (y/N) " ans
    if [[ "$ans" != "y" && "$ans" != "Y" ]]; then echo "Aborted."; exit 0; fi
  else
    echo "--force: proceeding without prompts"
  fi
fi

# Extract safely into a temp dir then move
EXTRACT_DIR=$(mktemp -d)
trap 'rm -rf "$EXTRACT_DIR"' EXIT

echo "Extracting archive into $EXTRACT_DIR ..."
tar -xzf "$ARCHIVE" -C "$EXTRACT_DIR"

# Move each top-level folder into appropriate location relative to / or TARGET_HOME
# Our archives were created from absolute paths copied into a workdir with leading path components relative to /
pushd "$EXTRACT_DIR" >/dev/null
for top in *; do
  # Detect original path from top-level content. Examples: home/username/.omp/agent/...
  echo "Processing $top"
  # Find the first file entry to detect original absolute prefix
  sample=$(find "$top" -mindepth 1 -maxdepth 3 | head -n1 || true)
  if [[ -z "$sample" ]]; then
    echo "Empty top-level entry: $top, skipping"; continue
  fi
  # We expect paths that start like home/<user>/.omp... or etc. We'll attempt heuristic moves.
  # If top begins with home, map home/<user> to /home/<user>
  if [[ "$top" == home ]]; then
    # iterate users
    for userdir in "$top"/*; do
      user=$(basename "$userdir")
      dest_home="/home/$user"
      echo "Restoring files for user $user to $dest_home"
      mkdir -p "$dest_home"
      if [[ $FORCE -eq 1 || ! -e "$dest_home/.omp" ]]; then
        cp -a "$userdir/." "$dest_home/"
      else
        echo "Target $dest_home already has data. Use --force to overwrite." >&2
      fi
    done
  else
    # If top looks like .omp (from current user's HOME copy), move into TARGET_HOME
    if [[ "$top" == .omp || "$top" == "home" ]]; then
      echo "Copying $top into $TARGET_HOME"
      mkdir -p "$TARGET_HOME"
      if [[ $FORCE -eq 1 || ! -e "$TARGET_HOME/$top" ]]; then
        cp -a "$top" "$TARGET_HOME/"
      else
        echo "Target $TARGET_HOME/$top exists. Use --force to overwrite." >&2
      fi
    else
      # Otherwise, copy into / preserving path
      echo "Copying $top into / (preserve absolute layout)"
      cp -a "$top" / || echo "Warning: failed to copy $top to /"
    fi
  fi
done
popd >/dev/null

# Post-restore message
echo "Restore completed (files copied)."
# Suggest chown if UID mismatch
echo "If ownerships appear wrong, run: sudo chown -R <uid>:<gid> $TARGET_HOME/.omp"

echo "Done. Please start OMP and verify sessions are visible."
exit 0
