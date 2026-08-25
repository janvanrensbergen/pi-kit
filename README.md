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

## Install into a new sandbox

### Option A — straight copy into the global config dir

```bash
git clone git@github.com:you/pi-kit ~/pi-kit
~/pi-kit/install.sh              # copies into ~/.pi/agent
```

`install.sh` copies the `skills/`/`prompts/`/`themes`/`extensions` folders and
the `settings.json` (which includes the `packages` list). Pi then
**auto-installs the bundled extension packages on the next start** (after the
project is trusted), so no separate `pi install` step is needed. To detect
them, run `pi` once after cloning.

Customizable via env:

```bash
TARGET=~/.pi/agent ./install.sh  # explicit global target (default)
./install.sh --target ./project/.pi   # project-level config
MODE=symlink ./install.sh        # symlink instead of copy
FORCE=1 ./install.sh             # overwrite existing settings.json
```

### Option B — install as a pi package

The kit is also a valid pi package (see `package.json`), so it can be pulled in
programmatically with version pinning and partial filtering:

```bash
pi install -l ./pi-kit        # project-local
pi install git:github.com/you/pi-kit   # from the repo
```

Project-level installs write into `.pi/settings.json`, which Pi auto-installs
on startup after the project is trusted.

## What's intentionally NOT installed

- `~/.pi/agent/auth.json` — provider credentials / API keys (per-sandbox)
- `~/.pi/agent/sessions/` — session history
- `models-store.json` / `enabledModels` — model catalogs and per-provider auth;
  keep those per-sandbox. Portable *preferences* (default model, thinking level)
  stay in `settings.json`.

Note on extension packages: the kit *repo* ships *config* (`packages` in
`settings.json`) but **not** the extension binaries or their runtime data. On a
fresh sandbox Pi `npm install`s the packages itself on startup (or, in the GHCR
image, they're pre-installed into `~/.pi/agent/npm/`). Per-sandbox state those
extensions accumulate (e.g. `pi-hermes-memory`'s SQLite DB, `pi-web-access`
query logs) stays local and is not part of the kit.

## Updating the kit

This kit is a snapshot of what I actually use. To pull your current config back
into the kit:

```bash
cp -r ~/.pi/agent/skills/* pi-kit/skills/
cp ~/.pi/agent/settings.json pi-kit/.global-settings.example.json
```

Then review + commit in the pi-kit repo.