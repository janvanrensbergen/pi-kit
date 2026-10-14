# JEV integrations in pi and omp

**Research date:** 2026-09-30; **updated 2026-10-14** (see [Update 2026-10-14](#update-2026-10-14)).  **Scope:** repositories and first-party package/index pages discoverable by searching for `Jev`/`JEV` alongside pi, omp, and Oh My Pi. “JEV” below means TypeSafe AI’s **Jev/System One** decision model, not an unrelated project that happens to use the same letters.

## Executive summary

There are confirmed Jev integrations for both ecosystems:

- **pi:** `iefnaf/pi-jev` (the clearest full-featured integration), `madeye/pi-jev`, `TheoOliveira/pi-jev`, `y0usaf/pi-jev`, and `legacybridge-tech/pi-typesafe-jev`.
- **omp:** `atulify/omp-plugin-jev-router` and `STRML/omp-jevens-classifier`.

These are separate projects, not one official pi/omp extension. Their approaches differ: context compaction, model/skill routing, retrieval, typed tools, prompt routing, and command-permission gating. The repository search also found `Talya1412/jev-harness`, which advertises integrations across multiple harnesses including pi and OMP; its README describes a multi-package harness rather than a single narrowly scoped extension, so it is listed as a related project rather than counted as a distinct confirmed pi/omp package here.

The linked OpenRouter example is **not** a pi or omp extension. `prismhq/jev-router` is a standalone LiteLLM/OpenRouter-compatible proxy: clients send `model: "jev-router"`, and the proxy optionally calls Jev to select among configured models. It can be used underneath an agent, but its source does not claim pi/omp integration.

## Update 2026-10-14

The ecosystem grew from 7 focused projects to roughly 50 in two weeks. Method: `gh search repos`, `npm search`, and the pi package index via `ketch`; repo metadata (pushed date, stars, archived flag, license) from the GitHub API; README openings read for the omp-relevant candidates. Star counts and push dates are as of 2026-10-14. Behaviour claims come from README text only; **no extension was installed or run**.

### What changed

- **omp now has a native Jev “judge” role.** `judge`/`judge_batch` exist in omp’s eval tool, backed by TypeSafe when credentialed and otherwise the smol chat model. Newer omp plugins (`omp-jev-tier`, `omp-jev-skills`, `omp-jev-tool`, `omp-jevify`, `omp-cua-jev`, `omp-jev-watchdog`) use that role instead of their own HTTP client, and so need no separate API key handling. Older plugins (`omp-jevens-classifier`, `omp-jev-router`) call the TypeSafe API directly.
- **A multi-harness package now exists:** `Novacon/ohmyjev` (npm `ohmyjev`, v0.12.0, MIT, pushed 2026-10-13) targets Claude Code, Codex, pi and omp. The pi index lists it as “Guardrails for coding agents”. It covers a destructive-command gate, prompt-injection screening, verbatim compaction, a skill picker, and per-turn effort/model routing via omp’s `@smol`/`@default`/`@slow` roles. Install: `omp plugin install ohmyjev`. Its README says omp does not ask for permission the way Claude Code does, so the auto-approve feature is not applicable there.
- **The previous “focused” list is stale in places.** `STRML/omp-jevens-classifier` is now **archived**. `Talya1412/jev-harness` was pushed today and now ships npm packages `@jev-harness/{kit,omp,pi}` v0.7.0. `TheoOliveira/pi-jev` is now v0.7.0 on npm as `pi-jev` (66 stars, pushed 2026-10-03). `y0usaf/pi-jev` is at 165 stars and is the most-starred pi-specific one, but its last push was 2026-10-01.
- **Curated lists exist now**, e.g. `yibie/awesome-jev` (2.3k stars), `heyjunpenn/awesome-jev`, `cobanov/awesome-jev`, `AbdelStark/awesome-typesafe-jev`. Use them for future inventory updates instead of re-searching; they were not audited here.

### omp-specific projects (new since 2026-09-30, unless noted)

Stars are low everywhere (0–12); treat all as immature. Licensing is MIT unless noted.

| Project | Area | Notes |
|---|---|---|
| `Novacon/ohmyjev` | Multi-feature bundle | See above. 2 stars, but most complete and actively pushed. |
| `jerryfane/omp-jev-compaction` | Verbatim compaction | 12 stars; TypeSafe or OpenRouter; vendors `tamaratran/fast-jev-compaction` core. |
| `Reamd7/omp-fast-jev-compaction` | Verbatim compaction | Port of `joelhooks/pi-fast-jev-compaction`; verified against omp 17.3.7 / 18.2.6 per README. |
| `BingChanCN/omp-jev-toolkit` | Compaction + tool-result sieve + file finder | Description only; no README found via API. |
| `d3d0n/omp-statify` | Large tool-output filtering | Recoverable; no license file. |
| `charliemartin0/omp-jev-tier` | Subagent tiering + auto plan mode | Uses omp’s native judge; README targets omp 18.8.4. |
| `danieljohnmorris/omp-jev-router` | Per-turn model + per-task agent routing | Also respects omp provider usage limits. No license. |
| `daviddl9/jev-router` | Planner/worker model split | OMP 18.1.16 / Pi 0.83.0. Licence `NOASSERTION`. |
| `priaculun/ontoken-auto-omp` | OnToken model routing | Tied to the OnToken provider; README in Indonesian. |
| `atulify/omp-plugin-jev-router` | Simple/advanced routing | From the earlier report; unchanged since 2026-09-21. |
| `ycs77/omp-jev-auto-approve` | Bash/eval/path approval | README warns that file contents are not inspected and `xd://`/`skill://` bypass path review. |
| `alexsatch/omp-auto-mode` | safe/ask/unsafe gate | 3 stars. |
| `cyriusweng/omp-jev-gate` | Gate | No description. |
| `siddicky/omp-typesafe` | Adversarial / advisory reviewer + `typesafe_ask` | Pushed 2026-10-13; npm `omp-typesafe` v0.2.0. Follows omp’s advisor pattern. |
| `seanperkins/omp-jev-watchdog` | Shadow-only verification watchdog | Author **stopped the trial on 2026-09-23**: no demonstrated useful catch. A useful negative data point. |
| `NomenAK/jev-tools` | Six evidence tools for pi/omp/MCP | npm `jev-agent-tools` v0.4.0; Jev-API-compatible. |
| `5c0r/omp-jev-skills`, `5c0r/omp-jev-tool` | Skill and tool discovery via Judge | Installed from a feature branch (PR review state). |
| `ericjuta/omp-jevify` | Skill: when to use `judge_batch` | Guidance on choosing deterministic tools vs. Jev. |
| `ericjuta/omp-cua-jev` | Guarded computer use | Uses Cua Driver; niche. |
| `gnoviawan/omp-jev-tools` | `jev_judge`, `jev_route`, … tools | No SPDX license. |
| `hoaphm/jev-decision-maker`, `dakai/omp-jev-web`, `hopletstudio/omp-jev-mcp-ranker` | Decision picker, browser tool, MCP ranker | 0 stars; experimental. |
| `luw2007/pi-jev-harness` | Pi + omp harness | Supersedes archived `luw2007/omp-jev-extensions`. |
| `iAziz786/omp-jev-decision`, `thejorgg/omp-jev` | — | **Archived.** |

### New pi-specific packages (npm)

`pi-jev` (TheoOliveira, 0.7.0), `@alexlikevibe/pi-jev` (iefnaf, 0.2.1), `@riposta/pi-jev`, `pi-jev-auto-mode`, `pi-jev-permit`, `pi-jev-guard`, `@bismawy/pi-jev-eye` (published 2026-10-14), `pi-jev-compaction`, `@gurkannz/pi-jev-compaction`, `pi-jev-context-curator`, `pi-jev-lens`, `pi-jev-redact`, `pi-jev-wiki`, `pi-jev-browser`, `@jkudish/jev-browser`, `@jkudish/jev-mcp`, `pi-jev-router`, `pi-jev-model-router` (+ profile switcher), `@sugarforever/pi-jev-router`, `@ejstembler/pi-classifier-router` (pi and omp), `@each1024/pi-jev-{route,reply}`, `brzewVCE/pi-jev-thinking-router` (effort-only routing; keeps model stable for cache continuity). Functional areas are the same as before: compaction, routing, permission gates, context shaping, retrieval, and browser agents.

### Assessment for this repo

- Recommendation from the earlier trial note (shadow mode, reassess in 4–6 weeks) still stands; nothing here shows production-grade maturity. Most omp plugins are under three weeks old with 0–12 stars, and one trial (`omp-jev-watchdog`) was abandoned for lack of benefit.
- Candidates worth trialing first, in shadow/non-blocking mode:
  1. **`Novacon/ohmyjev`**: broadest, maintained, omp-aware, and fails open to normal behaviour.
  2. **`jerryfane/omp-jev-compaction`**: narrowest-risk option if only compaction is wanted; it never rewrites user/assistant text.
  3. **`charliemartin0/omp-jev-tier`**: only if subagent model tiering matters; it relies on omp’s native judge and leaves model roles unchanged.
- Prerequisites: a `typesafe/jev-latest` judge role plus `TYPESAFE_API_KEY` or `/login typesafe`. Check that the sandbox network allow-list covers the TypeSafe API host before trialing; a blocked host will look like a Jev outage.
- Avoid for now: blocking permission gates (`omp-jev-auto-approve`, `omp-auto-mode`). They add a model-judged layer in front of omp’s own gate; `omp-jev-auto-approve` documents path-only review for file tools.
- The earlier caveat on completeness applies: this search was not exhaustive, and the count is inflated by forks/ports and awesome-lists.

## Confirmed pi projects

### `iefnaf/pi-jev` — selective compaction and per-turn routing

Repository: <https://github.com/iefnaf/pi-jev>

The project README identifies it as “Selective context compaction and per-turn model routing for pi, powered by Jev.” It declares three pi integrations: a `session_before_compact` hook that asks typed Jev questions about which tool calls/results to retain, a `before_agent_start` hook that classifies request difficulty and can switch to a cheap or strong model, and a `/jev` settings command. It supports TypeSafe and OpenRouter transports; the README gives the OpenRouter decisions endpoint as `https://openrouter.ai/api/alpha/decisions` and the Jev model as `typesafe/jev-1.13`.

Primary evidence: [README](https://raw.githubusercontent.com/iefnaf/pi-jev/main/README.md), especially the “Context compaction”, “Model routing”, and “Jev transports” sections. The README’s install command currently names the published package `npm:@alexlikevibe/pi-jev`, while the source repository is `iefnaf/pi-jev`; that distinction is recorded rather than inferred away.

### `madeye/pi-jev` — Jev-assisted retrieval and caching

Repository: <https://github.com/madeye/pi-jev>

The repository search result and project README describe a pi extension for file retrieval/request caching. Its modes distinguish full-file reads, local ranking, and a `jev` mode that calls `jev_search` with paths and a larger excerpt limit, adding hosted Jev judgment. This is a retrieval-oriented integration, not the same project as `iefnaf/pi-jev` despite the identical repository name suffix.

Primary evidence: [repository](https://github.com/madeye/pi-jev) and its [README](https://raw.githubusercontent.com/madeye/pi-jev/main/README.md). The repository is included because its own source/README explicitly describes the Jev mode; no claim is made about its publication status beyond what the repository exposes.

### `TheoOliveira/pi-jev` — semantic skill/tool routing

Repository: <https://github.com/TheoOliveira/pi-jev>

The project describes semantic tool routing and typed System One decisions for the pi coding agent. Its README says it injects matching skill recommendations into the turn, skips slash commands, empty prompts, and prompts while Jev is unconfigured or already evaluating, and fails open by leaving the turn untouched after a Jev failure. This is a prompt/skill recommendation integration rather than model routing or compaction.

Primary evidence: [repository](https://github.com/TheoOliveira/pi-jev) and [README](https://raw.githubusercontent.com/TheoOliveira/pi-jev/main/README.md).

### `y0usaf/pi-jev` — tool-call gate and typed questions

Repository: <https://github.com/y0usaf/pi-jev>

The project description identifies Jev as a decision layer for the pi coding agent, with a measured tool-call gate and `jev_ask` for typed, calibrated answers. This is a confirmed pi extension conceptually distinct from compaction/routing projects.

Primary evidence: [repository](https://github.com/y0usaf/pi-jev) and [README](https://raw.githubusercontent.com/y0usaf/pi-jev/main/README.md).

### `legacybridge-tech/pi-typesafe-jev` — five pi tools

Repository: <https://github.com/legacybridge-tech/pi-typesafe-jev>

The repository description says it exposes TypeSafe Jev judgments as five pi tools, leaving thresholds, weights, and resulting actions under code/user control. That makes it a tool-facing integration rather than an automatic router.

Primary evidence: [repository](https://github.com/legacybridge-tech/pi-typesafe-jev) and [README](https://raw.githubusercontent.com/legacybridge-tech/pi-typesafe-jev/main/README.md).

## Confirmed omp projects

### `atulify/omp-plugin-jev-router` — simple/advanced model-role routing

Repository: <https://github.com/atulify/omp-plugin-jev-router>

The README calls this an “OMP Jev Router”: an Oh My Pi extension that sends one typed `Choice` question to TypeSafe Jev for each eligible interactive prompt, then selects a configured simple or advanced OMP model role. It has explicit fail-open-to-advanced behavior for low confidence, malformed responses, API failures, timeouts, and image prompts; it also documents `/jev-route` commands and OMP 18.1.6 input scope.

Primary evidence: [README](https://raw.githubusercontent.com/atulify/omp-plugin-jev-router/main/README.md), including “How it works”, “Requirements”, and “Failure behavior”.

### `STRML/omp-jevens-classifier` — bash/eval permission gate

Repository: <https://github.com/STRML/omp-jevens-classifier>

This OMP plugin uses Jev’s typed answers to classify bash commands and process-spawning `eval` payloads. It places classification in front of OMP’s native bash gate, derives safe/unsafe/unsure outcomes from probabilities, and fails closed to a permission request (or blocks headless sessions) when Jev is unavailable. The README explicitly identifies Jev as TypeSafe’s System One model, uses `jev-latest` by default, and documents the HTTP request/typed question battery.

Primary evidence: [README](https://raw.githubusercontent.com/STRML/omp-jevens-classifier/main/README.md), especially “Requirements”, “Judgment: Jev”, and “Fails closed”.

## Related project: `Talya1412/jev-harness`

Repository: <https://github.com/Talya1412/jev-harness>

The repository description advertises TypeSafe Jev integrations for OMP, MCP, Claude Code, and pi, including fail-open routing/gating and compaction. It appears to be a broader multi-integration project, not a single pi package or OMP plugin with the focused scope of the projects above. Its repository is worth checking when a complete cross-harness inventory is needed, but the two OMP repositories and five pi repositories above are the directly identifiable focused extensions from the source search.

Primary evidence: [repository](https://github.com/Talya1412/jev-harness) and [README](https://raw.githubusercontent.com/Talya1412/jev-harness/main/README.md).

## OpenRouter `jev-router` and the linked example

### `prismhq/jev-router`

Repository: <https://github.com/prismhq/jev-router>

This is the likely referenced OpenRouter/typesafe example. Its README says it is an open-source LLM router built on LiteLLM: a client sends one model id (`jev-router`), the pre-call hook summarizes the request, filters eligible candidates, and chooses with `JevDecider` when `TYPESAFE_API_KEY` is set (otherwise a local cheapest-eligible `RulesDecider`). The configured candidates can be OpenRouter models. It is therefore **Jev itself used as a routing decision service**, not a pi/omp extension. The README explicitly presents it as an OpenAI-compatible proxy and says APIs/config are experimental.

Primary evidence: [README](https://raw.githubusercontent.com/prismhq/jev-router/main/README.md), plus source tree [jev_router](https://github.com/prismhq/jev-router/tree/main/jev_router).

### Distinguishing Jev from similarly named projects

The OpenRouter router and the extensions above use TypeSafe’s typed decision model: they refer to `TypeSafe`, `System One`, `jev-latest`/`typesafe/jev-*`, typed choices/scores/nouls, and/or the TypeSafe API. A name match alone is insufficient: this report does not count arbitrary repositories named `jev-router`, “jev” examples, browser playgrounds, or unrelated libraries as pi/omp extensions. In particular, a standalone OpenRouter Decisions API example is evidence of transport/model availability, not evidence that pi or omp loads it as an extension.

## Negative-result methodology and limits

Searches were performed against GitHub/repository source pages and official pi/omp pages using combinations of `Jev`, `JEV`, `pi`, `omp`, `Oh My Pi`, `extension`, `plugin`, and `router`; candidate repositories were then checked through their own README/source repository rather than relying on third-party summaries. The pi package index was also checked for `pi-jev`; its page was not fetchable in this environment (HTTP 403), so package-index metadata was not treated as stronger evidence than the source repository. Search results are a discovery method, not proof of completeness: private, unindexed, deleted, or newly published projects may be absent, and identical repository names make deduplication important.

As of the research date, it is **not correct to say that no pi/omp extensions use JEV**: the repositories listed above explicitly do. It is also **not correct to attribute `prismhq/jev-router` to pi or omp** without an adapter; its primary README describes a standalone LiteLLM proxy.

## Source links

- TypeSafe: <https://typesafe.ai/>
- pi package index result: <https://pi.dev/packages/pi-jev>
- OMP extension authoring docs: <https://omp.sh/docs/extension-authoring>
- OpenRouter: <https://openrouter.ai/>
