# omp-kit

Personal Oh My Pi (OMP) coding-agent toolkit: shared skills, themes, prompts,
extensions, and runtime preferences I use across sandboxes.

## Published artifacts

A GitHub Actions workflow (`.github/workflows/publish-omp.yml`) publishes to GHCR
on pushes to `main` that touch the OMP image, kits, or resources, and on `v*`
tags/releases:

- `ghcr.io/janvanrensbergen/omp-sandbox`: sandbox image built from `Dockerfile`
- `ghcr.io/janvanrensbergen/omp-kit:latest`: sbx kit from `kit-omp/spec.yaml`
- `ghcr.io/janvanrensbergen/kotlin-lsp-kit:latest`: Kotlin LSP mixin from `kit-kotlin-lsp/spec.yaml`

Start it with:

```bash
sbx run omp --kit ghcr.io/janvanrensbergen/omp-kit:latest
```

The OMP image pins `@oh-my-pi/pi-coding-agent` 18.10.4, installs Bun, runs
`rtk init -g --agent pi` for RTK's currently released Pi-compatible setup, and
ships `extensions/rtk.js` into OMP's extension directory so OMP bash calls are
rewritten through `rtk rewrite`. It starts directly with `[herdr]`, Herdr opens
new panes with `/bin/bash` by default, and the image ships a repo-owned `.bashrc`
with a colored prompt, git branch segment, history tuning, and shell aliases.
OMP's native resource locations. OMP 18.x has native task subagents, plan mode,
MCP, web search/fetch, and memory backends, so `omp/config.yml` intentionally
uses OMP-native `task.*`, `modelRoles`, `memory.backend`, and `autolearn`
settings. OMP's built-in
configuration and extension APIs are evolving, so compatibility gaps are
possible.

#### ohmyjev (Jev guardrails)

The image installs the `ohmyjev` OMP plugin (version pinned by `OHMYJEV_VERSION`
in the `Dockerfile`): Jev-judged bash and exfil gates, injection screening, stuck
and done checks, output trimming, skill picking, per-turn routing, and the
`find_code`/`ask_jev` tools. It finds its key in `TYPESAFE_API_KEY`, then
`OPENROUTER_API_KEY` (the kit injects the latter), and fails open when Jev is
slow, unsure, or unreachable. Background: `docs/jev-research.md`.

The image sets `writeGate false`. ohmyjev 0.12.0's write gate refuses every
`xd://` target as "outside the repo and allowPaths" (`allowPaths` cannot
whitelist a URL scheme), which blocks all tool devices (`xd://lsp`,
`xd://ast_edit`, MCP tools, and so on). Re-enable it once upstream exempts
`xd://`.

#### Kotlin LSP mixin

Kotlin LSP (JetBrains `kotlin-server`, which bundles its own JDK) is not baked
into the OMP image. Add it per sandbox with the `kotlin-lsp` mixin kit
(`kit-kotlin-lsp/spec.yaml`, published to
`ghcr.io/janvanrensbergen/kotlin-lsp-kit:latest`):

```bash
sbx run omp --kit ghcr.io/janvanrensbergen/omp-kit:latest \
  --kit ghcr.io/janvanrensbergen/kotlin-lsp-kit:latest
# or attach to an existing sandbox (recreates it, keeps packages and history):
sbx kit add <sandbox> ghcr.io/janvanrensbergen/kotlin-lsp-kit:latest
```

At sandbox creation it downloads the ~370 MB Marketplace package for the
sandbox architecture from `marketplace.visualstudio.com`, verifies its pinned
sha256, installs it under `~/.local/share/kotlin-lsp/<version>`, links
`~/.local/bin/kotlin-lsp`, and writes `~/.omp/agent/lsp.json`. To upgrade, bump
`VERSION` and both `SHA256` values in `kit-kotlin-lsp/spec.yaml`.

## What's inside

| Path | Purpose |
|------|---------|
| `skills/`  | Skill packages (Agent Skills format, one dir each) |
| `Dockerfile` | Builds the Oh My Pi sandbox image (published to `ghcr.io/janvanrensbergen/omp-sandbox`) |
| `kit-omp/spec.yaml` | Canonical OMP sbx kit spec (schemaVersion 2; zipped & published to `ghcr.io/janvanrensbergen/omp-kit`) |
| `kit-kotlin-lsp/spec.yaml` | Kotlin LSP mixin kit for the OMP sandbox (published to `ghcr.io/janvanrensbergen/kotlin-lsp-kit`) |
| `omp/config.yml` | Oh My Pi runtime resource-path configuration |
| `docs/` | Reference notes (e.g. GitHub Copilot model pricing) |
| `prompts/` `themes/` `extensions/` | Optional resource categories; `extensions/rtk.js` supplies the OMP RTK bash rewrite hook |

The RTK bash rewrite hook ships as a local OMP extension (`extensions/rtk.js`)
because RTK v0.48.0 does not yet install `--agent omp` directly.
