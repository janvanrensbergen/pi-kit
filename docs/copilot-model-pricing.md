# GitHub Copilot model pricing reference

Reference notes for choosing GitHub Copilot models for reasoning and coding.

> Pricing and model availability can change. Check the official documentation before making billing decisions.

## Official sources

- [Models and pricing for GitHub Copilot](https://docs.github.com/en/copilot/reference/copilot-billing/models-and-pricing)
- [Usage-based billing for individuals](https://docs.github.com/en/copilot/concepts/billing/usage-based-billing-for-individuals)
- [About Copilot auto model selection](https://docs.github.com/en/copilot/concepts/models/auto-model-selection)

## Credit and billing notes

- `1 AI credit = $0.01 USD`.
- Model prices are listed per 1 million tokens.
- A $100 additional-usage budget equals 10,000 AI credits.
- The current Copilot Max plan is listed at $100/month and includes 20,000 monthly AI credits: 10,000 base credits plus 10,000 flex credits.
- Paid plans receive a 10% model-cost discount when using automatic model selection in supported Copilot features.
- Code completions and next-edit suggestions are not billed in AI credits for paid plans.

## Recommended models

| Use case | Recommended model | Why |
|---|---|---|
| Everyday reasoning and coding | **Claude Sonnet 4.6** | Strong general-purpose model with a good quality/cost balance |
| Difficult reasoning, architecture, stubborn bugs | **Claude Opus 4.6** | Categorized as “Powerful”; use selectively because it is expensive |
| Main coding model | **GPT-5.3-Codex** | Specifically coding-focused, powerful, and relatively cost-efficient |
| Cheap routine coding and agent work | **Gemini 3.6 Flash** or **Gemini 3.7 Flash** | Very low cost; useful for boilerplate, simple fixes, and exploration |
| Cost-effective reasoning alternative | **GPT-5.6 Terra** or **Gemini 3.1 Pro** | Both are listed as “Powerful” at significantly lower rates than Opus/Sol; Gemini 3.1 Pro is preview |

## Rates for recommended models

All prices below are per 1 million tokens.

| Model | Category | Input | Cached input | Cache write | Output |
|---|---|---:|---:|---:|---:|
| Claude Sonnet 4.6 | Versatile | $3.00 | $0.30 | $3.75 | $15.00 |
| Claude Opus 4.6 | Powerful | $5.00 | $0.50 | $6.25 | $25.00 |
| GPT-5.3-Codex | Powerful | $1.75 | $0.175 | Not applicable | $14.00 |
| GPT-5.6 Terra | Versatile | $2.00 | $0.20 | $2.50 | $12.00 |
| GPT-5.6 Sol | Powerful | $5.00 | $0.50 | $6.25 | $30.00 |
| Gemini 3.1 Pro | Powerful | $2.00 | $0.20 | Not applicable | $12.00 |
| Gemini 3.6 Flash* | Versatile | $0.75 | $0.075 | Not applicable | $3.75 |
| Gemini 3.7 Flash* | Versatile | $0.75 | $0.075 | Not applicable | $3.75 |

\* Gemini 3.6 Flash and Gemini 3.7 Flash are listed at promotional pricing through December 31, 2026.

## Approximate cost comparison

Assumption: one interaction consumes **1 million input tokens + 100,000 output tokens**, excluding caching.

| Model | Approximate cost |
|---|---:|
| Claude Opus 4.6 | $7.50 |
| GPT-5.6 Sol | $8.00 |
| Claude Sonnet 4.6 | $4.50 |
| GPT-5.3-Codex | $3.15 |
| GPT-5.6 Terra | $3.20 |
| Gemini 3.6/3.7 Flash | $1.13 |

Actual Copilot tasks can be much cheaper or more expensive depending on context size, agent loops, and repeated model calls. Cached context is cheaper, but some models also charge for cache writes.

## Suggested workflow

1. Use **Auto** by default to let Copilot route tasks based on complexity, availability, and reliability.
2. Select **GPT-5.3-Codex** for implementing features, refactoring, writing tests, and code transformations.
3. Select **Claude Sonnet 4.6** for debugging and reasoning about unfamiliar code.
4. Select **Claude Opus 4.6** only for especially difficult reasoning or high-stakes architecture work.
5. Use **Gemini Flash** for boilerplate, documentation, simple test cases, and quick questions.
