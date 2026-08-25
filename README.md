# pi-kit

Personal Pi coding-agent toolkit: the skills, themes, prompts, extensions, and
preferences I use across sandboxes. This directory is the living source of my
Pi config — version it in its own git repo and install it into any fresh
sandbox.

## What's inside

| Path | Purpose |
|------|---------|
| `skills/`  | Skill packages (Agent Skills format, one dir each) |
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

Note on extension packages: the kit ships *config* (`packages` in
`settings.json`) but **not** the extension binaries or their runtime data. On a
fresh sandbox Pi `npm install`s the packages itself on startup; per-sandbox
state those extensions accumulate (e.g. `pi-hermes-memory`'s SQLite DB,
`pi-web-access` query logs) stays local and is not part of the kit.

## Updating the kit

This kit is a snapshot of what I actually use. To pull your current config back
into the kit:

```bash
cp -r ~/.pi/agent/skills/* pi-kit/skills/
cp ~/.pi/agent/settings.json pi-kit/.global-settings.example.json
```

Then review + commit in the pi-kit repo.