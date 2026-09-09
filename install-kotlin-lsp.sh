#!/usr/bin/env bash
set -euo pipefail
# install-kotlin-lsp.sh
# Installs JetBrains kotlin-server from the VS Code Marketplace vspackage (vsix gz) into
# /home/agent/.local/share/kotlin-lsp/<version>/server and symlinks /home/agent/.local/bin/kotlin-lsp
# Also creates /usr/local/bin/kotlin-lsp when run as root (build-time compatibility).

KOTLIN_LSP_VERSION="${KOTLIN_LSP_VERSION:-0.0.12}"
TARGET_PLATFORM_ENV="${KOTLIN_LSP_TARGET_PLATFORM:-}" # optional override

# Map Docker buildx TARGETPLATFORM if provided
if [ -n "${TARGETPLATFORM:-}" ] && [ -z "$TARGET_PLATFORM_ENV" ]; then
  case "${TARGETPLATFORM}" in
    *arm64*) TP=linux-arm64 ;;
    *amd64*|*x86_64*) TP=linux-x64 ;;
    *) TP=linux-x64 ;;
  esac
else
  TP=${TARGET_PLATFORM_ENV:-linux-arm64}
fi

VERS=${KOTLIN_LSP_VERSION}
TMPDIR=$(mktemp -d)
cd "$TMPDIR"

URL="https://marketplace.visualstudio.com/_apis/public/gallery/publishers/JetBrains/vsextensions/kotlin-server/${VERS}/vspackage?targetPlatform=${TP}"

echo "Downloading kotlin-server vsix from $URL"
curl -fL -o kotlin-server.vsix.gz "$URL"

# Decompress gzip -> .vsix
if command -v python3 >/dev/null 2>&1; then
  python3 - <<'PY'
import gzip, shutil
with gzip.open('kotlin-server.vsix.gz','rb') as src:
    with open('kotlin-server.vsix','wb') as dst:
        shutil.copyfileobj(src,dst)
PY
else
  gzip -d kotlin-server.vsix.gz
fi

unzip -q kotlin-server.vsix -d kotlin-server-vsix

INSTALL_DIR=/home/agent/.local/share/kotlin-lsp/${VERS}
mkdir -p "${INSTALL_DIR}"
cp -a kotlin-server-vsix/extension/server "${INSTALL_DIR}/server"

# Ensure executables
chmod +x "${INSTALL_DIR}/server/bin/intellij-server" || true
chmod +x "${INSTALL_DIR}/server/kotlin-lsp.sh" || true

mkdir -p /home/agent/.local/bin
ln -sfn "${INSTALL_DIR}/server/bin/intellij-server" /home/agent/.local/bin/kotlin-lsp

# Provide a root-owned fallback symlink for build-time checks
if [ "$(id -u)" = "0" ]; then
  mkdir -p /usr/local/bin
  ln -sfn /home/agent/.local/bin/kotlin-lsp /usr/local/bin/kotlin-lsp
fi

# Write OMP lsp.json configuration
mkdir -p /home/agent/.omp/agent
cat > /home/agent/.omp/agent/lsp.json <<'JSON'
{
  "servers": {
    "kotlin-lsp": {
      "command": "kotlin-lsp",
      "args": ["--stdio"],
      "fileTypes": [".kt", ".kts"],
      "languageId": "kotlin",
      "rootMarkers": [
        "settings.gradle.kts",
        "build.gradle.kts",
        "pom.xml",
        ".git",
        ".idea"
      ],
      "warmupTimeoutMs": 30000
    }
  }
}
JSON

# chown to agent user if exists
if id agent >/dev/null 2>&1; then
  chown -R agent:agent /home/agent/.local /home/agent/.omp || true
fi

# cleanup
cd /
rm -rf "$TMPDIR"

echo "kotlin-lsp ${VERS} installed to ${INSTALL_DIR}"
exit 0
