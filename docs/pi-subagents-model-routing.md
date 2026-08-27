# pi-subagents model routing

Research date: 2026-08-26. The installed package inspected in this environment is `pi-subagents@0.58.0` (`/home/agent/.pi/agent/npm/node_modules/pi-subagents/package.json:1-4`). The kit requests the package without a version pin, so a future install can change behavior (`settings.json:4-9`; `README.md:100-106`).

## Repository scout

- `settings.json` installs `npm:pi-subagents` and sets the parent Pi defaults to `openrouter/openai/gpt-5.6-luna-pro` with high thinking (`settings.json:4-14`). These are parent/global Pi settings; there is currently no `subagents` block.
- `.pi/settings.json` contains only an `enabledModels` allowlist (`.pi/settings.json:1-30`). The same list is packaged in `kit/files/workspace/.pi/settings.json`.
- `package.json` registers only the kit's skills, themes, prompts, and extensions; it does not define subagent agents (`package.json:7-12`).
- The repository has no project `.pi/agents/` definitions or per-agent model overrides. `skills/*/agents/openai.yaml` files are skill interface metadata, not pi-subagents agent definitions.
- The README declares `docs/` as the location for reference notes (`README.md:73-84`); this file establishes that convention.
- `.pi-settings.example.json:11` contains `github-copilot/claude-opus-4.6:medium/`, with a trailing slash. Treat it as a likely typo and validate before using it as a model example.

## Direct answer

For native Pi subagents, configure a different model per role with `subagents.agentOverrides.<agent>.model` in either the user settings file (`~/.pi/agent/settings.json`) or the project settings file (`.pi/settings.json`). Project settings win over user settings. Use `subagents.defaultModel` for the shared fallback and `agentOverrides` for exceptions. For a one-off launch, pass a per-run model override. The effective precedence, strongest first, is:

1. Per-run `model`.
2. Agent Markdown frontmatter `model`.
3. `subagents.agentOverrides.<name>.model`.
4. `subagents.defaultModel`.
5. The parent session model.

Source: installed `docs/models.md:5-15,19-61` and `docs/agents.md:192-218`.

## Persistent role routing

Add this to a live user or project Pi settings file. Do not copy it blindly into the kit: choose models that are actually available and authenticated in the target environment.

```json
{
  "subagents": {
    "defaultModel": "openrouter/openai/gpt-5.6-luna-pro",
    "defaultProvider": "openrouter",
    "defaultThinking": "medium",
    "agentOverrides": {
      "scout": {
        "model": "openrouter/deepseek/deepseek-v4-flash-0731",
        "thinking": "low"
      },
      "researcher": {
        "model": "openrouter/deepseek/deepseek-v4-flash-0731",
        "thinking": "low",
        "fallbackModels": ["github-copilot/gpt-5.5"]
      },
      "reviewer": {
        "model": "github-copilot/claude-sonnet-4.6",
        "thinking": "high"
      },
      "worker": {
        "model": "openrouter/openai/gpt-5.6-luna-pro",
        "thinking": "medium"
      }
    }
  }
}
```

The model names above are drawn from this kit's configured/example model lists (`.pi/settings.json:6-29`; `.pi-settings.example.json:4-30`). Availability, authentication, and exact registry resolution still need a live check.

`defaultProvider` only helps resolve bare IDs. Prefer fully-qualified `provider/model` strings for role routing. `subagents.defaultThinking` is independent from the parent's `defaultThinkingLevel`; explicit per-agent `thinking` wins. Thinking levels are appended as `:off`, `:minimal`, `:low`, `:medium`, `:high`, `:xhigh`, or `:max` at runtime (`docs/models.md:94-124`).

## One-run routing

For a single invocation, use a tool-call/workflow child model override or the slash-command form:

```text
/run reviewer[model=github-copilot/claude-sonnet-4.6:high] "Review the current diff for regressions"
```

In a scripted workflow, set `model` on the child task:

```js
const results = await runs.all([
  { key: "cheap-scout", agent: "scout", model: "openrouter/deepseek/deepseek-v4-flash-0731", task: "Map the relevant code" },
  { key: "deep-review", agent: "reviewer", model: "github-copilot/claude-sonnet-4.6:high", task: "Review the current diff" }
]);
```

The tool schema documents `model` on sequential, parallel, and dynamic workflow children (`docs/tool-reference.md:1-53`; installed source `src/extension/schemas.ts`, `ParallelTaskSchema`, `DynamicParallelTemplateSchema`, and `ChainItem`).

## Custom agents

A project agent is a Markdown file under `.pi/agents/**/*.md` with YAML frontmatter. Pin its default model there when the model is part of the agent's durable identity:

```yaml
---
name: model-aware-researcher
description: Research using a fast model
model: openrouter/deepseek/deepseek-v4-flash-0731
fallbackModels:
  - github-copilot/gpt-5.5
thinking: low
inheritProjectContext: true
---

Use official sources and cite every claim.
```

Agent definitions are discovered from builtin, package, user, and project locations, with project definitions taking precedence on collisions (`docs/agents.md:3-31`). Supported model-related frontmatter fields are `model`, `fallbackModels`, and `thinking` (`docs/agents.md:246-280`). A settings override can fill fields left unset by a matching custom agent while preserving its persona (`docs/agents.md:212-218`).

## Fallbacks and restrictions

- `fallbackModels` is an ordered backup chain for provider/model failures such as quota, authentication, timeout, or unavailable-model errors. Ordinary task failures do not trigger it (`docs/agents.md:160-170`).
- `subagents.modelScope` is a policy gate, not a selector. Use `agentOverrides.<name>.model` to select a model, then use `modelScope.agents.<name>.allow` to constrain the resolved primary and fallback candidates (`docs/models.md:175-207`).
- With `enforce: true` and `strict: true`, out-of-scope inherited, frontmatter, explicitly selected, and fallback models are rejected. The literal `inherit` allows the current parent model (`docs/models.md:177-207`).
- `model: "inherit"` explicitly chooses the current parent model. For nested children, it means the immediate parent's current model, not necessarily the top-level parent's original model (`docs/models.md:13-15,203-205`).

Example policy:

```json
{
  "subagents": {
    "agentOverrides": {
      "worker": {
        "model": "openrouter/openai/gpt-5.6-luna-pro"
      }
    },
    "modelScope": {
      "enforce": true,
      "strict": true,
      "allow": ["openrouter/*", "github-copilot/*"],
      "agents": {
        "worker": {
          "allow": ["openrouter/openai/gpt-5.6-luna-pro"]
        }
      }
    }
  }
}
```

## Native versus external agents

The model controls above apply to native Pi children, including builtin, package, user, and project agents. External CLI profiles (`codex-exec`, `claude-code`, `cursor-agent`, and writer variants) have adapter-owned runner contracts. Do not assume native `model`, `fallbackModels`, `thinking`, `modelScope`, tools, or context options configure the external CLI unless that adapter explicitly implements them (`docs/agents.md:58-69,175-186`).

## Verification checklist

1. Ensure the chosen model appears in the live registry and is authenticated.
2. Reload/restart Pi after settings or agent changes.
3. Run `/subagents-models` and `/subagents-models reviewer` to inspect the effective mapping (`docs/models.md:151-160`).
4. Use fully-qualified model IDs when providers expose similarly named models.
5. If reproducibility matters, pin `npm:pi-subagents@0.58.0` rather than the current unversioned package entry, then re-check the installed docs and behavior.

## Sources

- Installed primary source: `/home/agent/.pi/agent/npm/node_modules/pi-subagents/docs/models.md` (package `0.58.0`), covering precedence, defaults, thinking, fuzzy resolution, scopes, and profiles.
- Installed primary source: `/home/agent/.pi/agent/npm/node_modules/pi-subagents/docs/agents.md` (package `0.58.0`), covering discovery, frontmatter, overrides, and external runner boundaries.
- Installed primary source: `/home/agent/.pi/agent/npm/node_modules/pi-subagents/docs/tool-reference.md` (package `0.58.0`), covering per-child workflow `model` parameters and live mapping commands.
- Installed source: `/home/agent/.pi/agent/npm/node_modules/pi-subagents/src/agents/agents.ts`, including settings parsing, model defaults, model fields, and agent override application.
- Repository sources: `README.md`, `settings.json`, `.pi/settings.json`, `.pi-settings.example.json`, `package.json`.
- Upstream versioned docs: [models.md](https://raw.githubusercontent.com/nicobailon/pi-subagents/v0.58.0/docs/models.md), [agents.md](https://raw.githubusercontent.com/nicobailon/pi-subagents/v0.58.0/docs/agents.md), [configuration.md](https://raw.githubusercontent.com/nicobailon/pi-subagents/v0.58.0/docs/configuration.md), [tool-reference.md](https://raw.githubusercontent.com/nicobailon/pi-subagents/v0.58.0/docs/tool-reference.md).

## Gaps

- The kit currently does not pin `pi-subagents`, so this note describes the installed `0.58.0` behavior, not a permanent guarantee.
- The model registry may change independently of this repository. `/subagents-models` is the runtime authority.
- External CLI model selection remains adapter-specific and requires inspecting the selected adapter's implementation/configuration.
