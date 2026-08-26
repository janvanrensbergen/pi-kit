# pi-kit

Personal Pi coding-agent toolkit: the skills, themes, prompts, extensions, and
preferences I use across sandboxes. This directory is the living source of my
Pi config — version it in its own git repo and install it into any fresh
sandbox.

## GitHub-published sandbox image and kit

The repo builds and publishes two artifacts to GitHub Container Registry (GHCR):

1. **`ghcr.io/janvanrensbergen/pi-sandbox`**: The Docker sandbox container image with pi pre-installed globally and the kit baked in as an installed pi package from the root `Dockerfile`.
2. **`ghcr.io/janvanrensbergen/pi-kit`**: The Docker Sandbox kit artifact, packaged as a zip containing `kit/spec.yaml` (schemaVersion 2).

A fresh sandbox pulls the `pi-sandbox` image with pi already installed globally and the kit registered as an installed pi package:

- **pi** (the agent binary, pinned via `ARG PI_VERSION`)
- **portable preferences**, from `settings.json` baked into `~/.pi/agent/settings.json`
- **the kit's skills/themes/prompts/extensions**, resolved from `/opt/pi-kit`
  (the Dockerfile runs `pi install /opt/pi-kit` at build time)
- **the five extension packages, pre-installed** into the image so first boot does
  no package auto-install and no network fetch

The image is built with a **single-stage** `Dockerfile`: install pi globally as
the `agent` user (package `@earendil-works/pi-coding-agent@${PI_VERSION}`),
`COPY . /opt/pi-kit` (filtered by `.dockerignore`), then write
`settings.json` to `~/.pi/agent/settings.json`, run `pi install /opt/pi-kit`
to register `/opt/pi-kit` as a local-path pi package in the sandbox's global
`~/.pi/agent/settings.json`, and `pi install` the five extension packages so
they are present in the image (versions float to latest at build time).

**When it publishes**: a GitHub Actions workflow (`.github/workflows/publish.yml`)
runs on every push to `main` touching `Dockerfile`, the workflow, `kit/**`, or kit resources, and on any
`v*` release/tag.

**Artifact tags**: `latest` (from `main`)

- `sha-<short>` for every build
- `v<version>` for semver tags (e.g. tag `v0.1.0` → `0.1.0`)

The packages are set **public** so sandboxes can pull them without credentials.

The `kit/spec.yaml` is the canonical sbx kit spec. Its `sandbox.image` points
at the published GHCR image (`ghcr.io/janvanrensbergen/pi-sandbox:latest`), and `sandbox.entrypoint` is `[pi, --approve]`.

The pi version is pinned in the Dockerfile via `ARG PI_VERSION` (default
`0.84.3`). To publish a different pi, bump that default (and the matching
`build-args` in the workflow).

### Starting a sandbox from this kit

Using the published kit from GHCR:

```bash
sbx run pi --kit ghcr.io/janvanrensbergen/pi-kit:latest
```

or create directly:

```bash
sbx create --kit ghcr.io/janvanrensbergen/pi-kit:latest
```

or straight from the container image:

```bash
sbx <name> --image ghcr.io/janvanrensbergen/pi-sandbox:latest
```

All end with a pi-ready environment: `pi` is present, `OPENROUTER_API_KEY` is
injected, domains are allowlisted, and `NO_PROXY` is set.

## What's inside

| Path | Purpose |
|------|---------|
| `skills/`  | Skill packages (Agent Skills format, one dir each) |
| `Dockerfile` | Builds the pi-pre-installed sandbox image (published to `ghcr.io/janvanrensbergen/pi-sandbox`) |
| `kit/spec.yaml` | Canonical sbx kit spec (schemaVersion 2; zipped & published to `ghcr.io/janvanrensbergen/pi-kit`) |
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

In the **GHCR sandbox image** the packages are pre-installed at build time
(floating to latest), so first boot performs no package auto-install for the
bundled selection.

Package versions **float to latest** at install time (e.g. `npm:pi-subagents` →
current latest). To pin a version for reproducible installs, change the entry to
`npm:pi-subagents@<version>`.
