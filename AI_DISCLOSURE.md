---
disclosure-default: ai-generated
models-used:
  - claude-opus-5
providers:
  - Anthropic
scope: |
  Human work is concentrated on core library code and documentation.
  An AI model is frequently employed to generate tests, benchmarks, and review handwritten code.
  Autonomous AI work is banned altogether; all work begins with an explicit human action.
last-updated: 2026-08-22
---

# AI Disclosure

Ignis follows the [`ai-disclosure` convention](https://github.com/ggfevans/ai-disclosure). See per-file headers for overrides.

## Overriding

Each file may specify an `SPDX-AI-Disclosure:` tag to override the repository's default disclosure level. Accepted values for this tag are as follows:

| Value          | Means                                                                       |
|----------------|-----------------------------------------------------------------------------|
| `none`         | No AI involvement. Use when you want to positively assert human authorship. |
| `ai-assisted`  | Human-authored; AI edited, refined, or filled in boilerplate.               |
| `ai-generated` | AI-generated with human prompting and review.                               |
| `autonomous`   | AI-generated without meaningful human oversight.                            |

## Reporting

This repository maintains a script at `/tool/disclosure.dart` that helps maintainers (and users) understand the scope of AI involvement by presenting a summary of all disclosure tags in a table. This table is automatically regenerated in CI and made available at [`/internals/ai-disclosure`](https://ignis.misha.jp/internals/ai-disclosure).
