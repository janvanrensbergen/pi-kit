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
- `ghcr.io/janvanrensbergen/anthropic-kit:latest`: Anthropic provider mixin from `kit-anthropic/spec.yaml`
- `ghcr.io/janvanrensbergen/openrouter-kit:latest`: OpenRouter provider mixin from `kit-openrouter/spec.yaml`
- `ghcr.io/janvanrensbergen/copilot-kit:latest`: GitHub Copilot provider mixin from `kit-copilot/spec.yaml`

Model providers are separate mixin kits. The base `omp-kit` carries only the
provider-neutral `github` credential (`GH_TOKEN`) and general egress. Each
provider mixin adds its own egress domains and proxy-managed API key
(`ANTHROPIC_API_KEY`, `OPENROUTER_API_KEY`, `COPILOT_GITHUB_TOKEN`). Select any
combination with repeated `--kit` flags:

```bash
sbx run omp --kit ghcr.io/janvanrensbergen/omp-kit:latest \
  --kit ghcr.io/janvanrensbergen/copilot-kit:latest \
  --kit ghcr.io/janvanrensbergen/openrouter-kit:latest \
  --kit ghcr.io/janvanrensbergen/anthropic-kit:latest
```

The workspace config (`kit-omp/files/workspace/.omp/config.yml`) defaults to
`github-copilot` models and uses `openrouter` for the Jev judge role, so those
two mixins match the shipped defaults; with other combinations, change the
default models. Add a provider to a running sandbox with
`sbx kit add <sandbox> <ref>` only if the sbx version supports credential
mixins there (unverified).

#### Zsh helper

A zsh function that creates (or reattaches to) a per-directory sandbox with the
Copilot and OpenRouter mixins by default. Add more kits with `--kit REF`,
Kotlin LSP with `-k`, and extra static MCPs with `--mcp NAME`. Kits and MCPs
are fixed at sandbox creation, so options are ignored for an existing sandbox.

```zsh
.omp() {
    local image=ghcr.io/janvanrensbergen/omp-kit:latest
    local -a kotlin kit_opts mcp_opts help
    local -a kits=(
        ghcr.io/janvanrensbergen/copilot-kit:latest
        ghcr.io/janvanrensbergen/openrouter-kit:latest
    )
    local -a mcps=(idea-stream atlassian) create_args=()
    local i

    zparseopts -D -F -K -- \
        k=kotlin -kotlin=kotlin \
        -kit+:=kit_opts \
        -mcp+:=mcp_opts \
        h=help -help=help || return 1

    if (( $#help )); then
        print -r -- "usage: .omp [-k|--kotlin] [--kit REF]... [--mcp NAME]... [name]"
        print -r -- "default kits: copilot, openrouter (anthropic: --kit ghcr.io/janvanrensbergen/anthropic-kit:latest)"
        return 0
    fi

    # zparseopts stores option/value pairs; keep the values (strip "=" from --opt=value).
    for (( i = 2; i <= $#kit_opts; i += 2 )); do kits+=("${kit_opts[i]#=}"); done
    for (( i = 2; i <= $#mcp_opts; i += 2 )); do mcps+=("${mcp_opts[i]#=}"); done
    (( $#kotlin )) && kits+=(ghcr.io/janvanrensbergen/kotlin-lsp-kit:latest)

    # Drop duplicates (e.g. --kit copilot-kit given explicitly), keep order.
    kits=("${(@u)kits}")
    mcps=("${(@u)mcps}")

    local name="${1:-${PWD:t}-omp${kotlin:+-kt}}"

    if sbx list 2>/dev/null |
        awk -v name="$name" '$1 == name { found = 1 } END { exit !found }'
    then
        # Existing sandbox: kits and static MCPs are fixed at creation.
        (( $#kit_opts + $#mcp_opts + $#kotlin )) &&
            print -u2 -- ".omp: '$name' exists; ignoring --kit/--mcp/--kotlin"
        sbx run "$image" --name "$name"
    else
        for i in "${kits[@]}"; do create_args+=(--kit "$i"); done
        for i in "${mcps[@]}"; do create_args+=(--static-mcp "$i"); done
        sbx run "$image" --name "$name" "${create_args[@]}"
    fi
}
```

The OMP image installs the standalone `omp` binary pinned to 19.0.0, runs
`rtk init -g --agent pi` for RTK's currently released Pi-compatible setup, and
ships `extensions/rtk.js` into OMP's extension directory so OMP bash calls are
rewritten through `rtk rewrite`. It starts directly with `[herdr]`, Herdr opens
new panes with `/bin/bash` by default, and the image ships a repo-owned `.bashrc`
with a colored prompt, git branch segment, history tuning, and shell aliases.
OMP's native resource locations. OMP 19.x has native task subagents, plan mode,
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

#### Linking subfolder workspaces to the sandbox-root `.omp`

The kit installs `.omp` only in the sandbox's top folder. Herdr workspaces
for sibling project subfolders (`cd` into `Harmonix/`, `efti/`, ...) run
`omp` there without their own `.omp`. OMP already inherits `SYSTEM.md`,
`RULES.md`, `AGENTS.md`, and `skills/` from the nearest ancestor `.omp`, but
`mcp.json`, `settings.json`, `config.yml`, `commands/`, `rules/`, `prompts/`,
`instructions/`, `hooks/`, `tools/`, and `extensions/` are only read from
`<cwd>/.omp` directly, with no ancestor walk.

`bash/omp-link-parent` (installed as `omp-link-parent` on `PATH`) symlinks
just those entries from `../.omp` into `./.omp`. Run it once per subfolder:

```bash
cd Harmonix
omp-link-parent           # fails if ./.omp already exists
omp-link-parent --force   # replaces colliding entries, backing up real files/dirs as <name>.bak-<timestamp>
```

`herdr/config.toml` binds `prefix+alt+o` to a popup running the plain command,
and `prefix+alt+shift+o` to the `--force` variant, both in the focused pane's
directory. Custom Herdr command keybindings are static, so `--force` needs its
own binding rather than a runtime argument.

## What's inside

| Path | Purpose |
|------|---------|
| `skills/`  | Skill packages (Agent Skills format, one dir each) |
| `Dockerfile` | Builds the Oh My Pi sandbox image (published to `ghcr.io/janvanrensbergen/omp-sandbox`) |
| `kit-omp/spec.yaml` | Canonical OMP sbx kit spec (schemaVersion 2; zipped & published to `ghcr.io/janvanrensbergen/omp-kit`) |
| `kit-anthropic/spec.yaml`, `kit-openrouter/spec.yaml`, `kit-copilot/spec.yaml` | Model-provider mixin kits (egress + proxy-managed API key; published to `ghcr.io/janvanrensbergen/{anthropic,openrouter,copilot}-kit`) |
| `kit-kotlin-lsp/spec.yaml` | Kotlin LSP mixin kit for the OMP sandbox (published to `ghcr.io/janvanrensbergen/kotlin-lsp-kit`) |
| `omp/config.yml` | Oh My Pi runtime resource-path configuration |
| `docs/` | Reference notes (e.g. GitHub Copilot model pricing) |
| `prompts/` `themes/` `extensions/` | Optional resource categories; `extensions/rtk.js` supplies the OMP RTK bash rewrite hook |
| `bash/omp-link-parent` | Symlinks a subfolder workspace's `.omp` to the sandbox-root `.omp` (see above); bound to `prefix+alt+o` / `prefix+alt+shift+o` (`--force`) in `herdr/config.toml` |

The RTK bash rewrite hook ships as a local OMP extension (`extensions/rtk.js`)
because RTK v0.48.0 does not yet install `--agent omp` directly.
