Kotlin LSP integration for kit-omp

This repository adds optional installation of JetBrains Kotlin LSP (kotlin-server VS Code extension) into the kit-omp Docker image.

Images
- slim: default; smaller image without Kotlin LSP pre-installed.
- full: larger image with Kotlin LSP pre-installed. Built by passing BUILD_KOTLIN_LSP=1 to Docker build.

How the install works
- At build time (full image): the Dockerfile calls /usr/local/bin/install-kotlin-lsp.sh which downloads the VSIX package from Visual Studio Marketplace for the proper platform, decompresses it, copies the extension/server into /home/agent/.local/share/kotlin-lsp/<version>/server, makes the server executable, symlinks /home/agent/.local/bin/kotlin-lsp, and writes /home/agent/.omp/agent/lsp.json.
- At runtime (slim image): use /usr/local/bin/install-kotlin-lsp.sh to install on demand. The script accepts env overrides via KOTLIN_LSP_VERSION and KOTLIN_LSP_TARGET_PLATFORM.

Buildx in CI
- The GitHub Actions workflow .github/workflows/dockerx.yml builds both variants (slim/full) for linux/amd64 and linux/arm64 and publishes to GHCR.
- The full image verification runs the following inside an amd64-emulated container: command -v kotlin-lsp; test -x $(command -v kotlin-lsp); readlink -f $(command -v kotlin-lsp); kotlin-lsp --version

Notes
- Full image size increases by ~200-500MB due to the bundled extension.
- KOTLIN_LSP_VERSION defaults to latest; pin via build arg KOTLIN_LSP_VERSION when building.
- The Marketplace API returns gzip-compressed .vsix content; the script decompresses then unzips.
- Ensure HTTP(S)_PROXY and JAVA_TOOL_OPTIONS are set in container runtime if required by environment.