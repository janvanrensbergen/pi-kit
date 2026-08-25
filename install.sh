#!/usr/bin/env bash
# pi-kit install script
#
# Installs this kit's skills/themes/prompts/extensions + settings into a
# target Pi config dir. Default target is the global config (~/.pi/agent).
# Pass a target to install into a project instead:
#
#   ./install.sh --target /path/to/project/.pi     # project-level
#   TARGET=~/.pi/agent ./install.sh                # explicit global
#
# Idempotent: safe to re-run, copies over existing files.
set -euo pipefail

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${TARGET:-${1:-$HOME/.pi/agent}}"
MODE="${MODE:-copy}"   # copy (default) copies; "symlink" links instead

if [[ "$MODE" == "symlink" ]]; then
  LINK="ln -sfn"
else
  LINK="cp -R"
fi

echo "installing pi-kit -> $TARGET (mode=$MODE)"

mkdir -p "$TARGET"

# Resource categories (copy whole dir tree)
for d in skills prompts extensions themes; do
  if [ -d "$KIT_DIR/$d" ] && [ -n "$(ls -A "$KIT_DIR/$d")" ]; then
    mkdir -p "$TARGET/$d"
    echo "  - $d"
    # shellcheck disable=SC2086
    for item in "$KIT_DIR/$d"/*; do
      [ -e "$item" ] || continue
      $LINK "$item" "$TARGET/$d/"
    done
  fi
done

# Settings (only if not already present, unless FORCE=1)
if [ -f "$KIT_DIR/settings.json" ]; then
  if [ ! -f "$TARGET/settings.json" ] || [ "${FORCE:-0}" = "1" ]; then
    echo "  - settings.json"
    cp "$KIT_DIR/settings.json" "$TARGET/settings.json"
  else
    echo "  - settings.json (exists, skipped; set FORCE=1 to overwrite)"
  fi
fi

echo "done. Note: model lists / API keys are intentionally NOT installed."
echo "Run 'pi /reload' or restart pi to pick up changes."