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
cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

cd "$TMPDIR"

URL="https://marketplace.visualstudio.com/_apis/public/gallery/publishers/JetBrains/vsextensions/kotlin-server/${VERS}/vspackage?targetPlatform=${TP}"

echo "[kotlin-lsp] Downloading kotlin-server ${VERS} for ${TP}"
curl_error_log=curl-error.log
http_status=$(curl --fail --location --silent --show-error --output kotlin-server.vsix.gz --write-out '%{http_code}' "$URL" 2>"$curl_error_log") || {
  curl_exit=$?
  echo "[kotlin-lsp] ERROR: download failed (HTTP status: ${http_status:-unknown}, curl exit: ${curl_exit})" >&2
  if [ -s "$curl_error_log" ]; then
    echo "[kotlin-lsp] curl details:" >&2
    cat "$curl_error_log" >&2
  fi
  exit 1
}
if [ "$http_status" != 200 ]; then
  echo "[kotlin-lsp] ERROR: download returned HTTP status ${http_status}" >&2
  exit 1
fi
if [ ! -s kotlin-server.vsix.gz ]; then
  echo "[kotlin-lsp] ERROR: download produced an empty or missing file" >&2
  exit 1
fi
echo "[kotlin-lsp] Download complete (HTTP ${http_status})"

echo "[kotlin-lsp] Decompressing package"
# Decompress gzip -> .vsix
if command -v python3 >/dev/null 2>&1; then
  if ! python3 - <<'PY'
import gzip, shutil
with gzip.open('kotlin-server.vsix.gz','rb') as src:
    with open('kotlin-server.vsix','wb') as dst:
        shutil.copyfileobj(src,dst)
PY
  then
    echo "[kotlin-lsp] ERROR: downloaded file is not a valid gzip package" >&2
    exit 1
  fi
else
  if ! gzip -d kotlin-server.vsix.gz; then
    echo "[kotlin-lsp] ERROR: failed to decompress downloaded package" >&2
    exit 1
  fi
fi
if [ ! -s kotlin-server.vsix ]; then
  echo "[kotlin-lsp] ERROR: decompressed package is empty or missing" >&2
  exit 1
fi

echo "[kotlin-lsp] Extracting package"
if ! unzip -q kotlin-server.vsix -d kotlin-server-vsix; then
  echo "[kotlin-lsp] ERROR: failed to extract kotlin-server.vsix" >&2
  exit 1
fi
if [ ! -d kotlin-server-vsix/extension/server ]; then
  echo "[kotlin-lsp] ERROR: extracted package does not contain extension/server" >&2
  exit 1
fi
echo "[kotlin-lsp] Extraction complete"
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
