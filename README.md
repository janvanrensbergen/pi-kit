# pi-kit

Personal Pi coding-agent toolkit: the skills, themes, prompts, extensions, and
preferences I use across sandboxes. This directory is the living source of my
Pi config — version it in its own git repo and install it into any fresh
sandbox.

## GitHub-published sandbox image

The repo builds a **sandbox image with pi + the whole kit pre-installed** from the
root `Dockerfile` and publishes it to GitHub Container Registry as
`ghcr.io/janvanrensbergen/pi-kit`. The image bakes everything, so a fresh sandbox
boots fully configured with no first-boot npm or copy step:

- **pi** (the agent binary, pinned via `ARG PI_VERSION`)
- **the kit's skills/themes/prompts/extensions**, resolved from `/opt/pi-kit`
  (the Dockerfile's multi-stage `bake` stage runs `pi install /opt/pi-kit`)
- **`settings.json` preferences**, baked as the global `~/.pi/agent/settings.json`
- **the five extension packages**, already materialized into `~/.pi/agent/npm/`

The `bake` stage assembles `~/.pi` + `/opt/pi-kit` at build time (network), and
the final `runtime` stage copies only that finished state across — the published
image stays lean and runs offline.

**When it publishes**: a GitHub Actions workflow (`.github/workflows/publish.yml`)
runs on every push to `main` touching `Dockerfile`/the workflow, and on any
`v*` release/tag.

**Image tags**:  `latest` (from `main`)

- `sha-<short>` for every build
- `v<version>` for semver tags (e.g. tag `v0.1.0` → `ghcr.io/janvanrensbergen/pi-kit:0.1.0`)

The package is set **public** so sandboxes can pull it without credentials.

The root `spec.yaml` is the canonical sbx kit spec. Its `agent.image` points
at the published GHCR image, and `agent.entrypoint.run` is `[pi, --approve]`.

The pi version is pinned in the Dockerfile via `ARG PI_VERSION` (default
`0.84.3`). To publish a different pi, bump that default (and the matching
`build-args` in the workflow).

### Starting a sandbox from this kit

Straight from the OCI registry:

```bash
sbx <name> --image ghcr.io/janvanrensbergen/pi-kit:latest
```

or from the repo's tracked `spec.yaml` (see the sbx CLI docs for how to point a
kit at a GitHub spec):

```bash
sbx create --kit git:github.com/janvanrensbergen/pi-kit
```

Both end with a pi-ready environment: `pi` is present, `OPENROUTER_API_KEY` is
injected, domains are allowlisted, and `NO_PROXY` is set.

## What's inside

| Path | Purpose |
|------|---------|
| `skills/`  | Skill packages (Agent Skills format, one dir each) |
| `Dockerfile` | Builds the pi-pre-installed sandbox image (published to GHCR) |
| `spec.yaml` | Canonical sbx kit spec (agent.image → GHCR image, entrypoint `[pi, --approve]`) |
| `settings.json` | Portable preferences, incl. the `packages` list of extensions to install |
| `.global-settings.example.json` | Snapshot of my global `~/.pi/agent/settings.json` |
| `.pi-settings.example.json` | Snapshot of a project-level `.pi/settings.json` |
| `docs/` | Reference notes (e.g. GitHub Copilot model pricing) |
| `prompts/` `themes/` `extensions/` | Optional categories (empty by default) |

### Bundled extensions

The kit's `settings.json` lists extension packages under `"packages"` so every
sandbox gets the same tooling. Pi auto-installs any listed package that isn't
present when it starts (after the project is trusted):

| Package | What it adds |
|---------|-------------|
| `npm:pi-subagents` | Sub-agent delegation (`scout`, `reviewer`, `worker`, `oracle`), `/council` |
| `npm:@narumitw/pi-plan-mode` | Codex-style `/plan` mode (plans before editing) |
| `npm:pi-hermes-memory` | Persistent memory + session search + secret scanning |
| `npm:pi-mcp-adapter` | Lazy MCP server adapter (`/mcp`) |
| `npm:pi-web-access` | Web search / fetch / GitHub clone / PDF / YouTube |

In the **GHCR sandbox image** these are already installed into
`~/.pi/agent/npm/` at build time, so a fresh sandbox boots with all five present
and pi performs no first-boot install.

Package versions **float to latest** at install time (e.g. `npm:pi-subagents` →
current latest). To pin a version for reproducible installs, change the entry to
`npm:pi-subagents@<version>`.
