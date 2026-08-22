---
title: AI Disclosure
description: Documents human-AI authorship.
lane: internals
category: internal
status: complete
---
<!-- SPDX-AI-Disclosure: none -->

I, [@misha](https://github.com/misha), am not a proponent of generative AI, especially in the context of game development. I will **never** use AI to create game assets like art and music. Despite this predisposition, I recognize that in the context of software engineering, generative AI can be a potent tool. I also believe its usage does not excuse the programmer from reviewing, and ultimately understanding, the generated code.

For Ignis, I have elected to use AI to help me write, maintain, and test the engine. The alternative would be the inability to ship it in an acceptable time frame, and I would rather have it exist with some AI-generated code *today* than not at all.

## Authorship Tracking

In the near future, I will target certain authorship thresholds, e.g. "the core library must be 100% human-owned". In order to enforce this, authorship is explicitly tracked using this [AI Disclosure](https://github.com/ggfevans/ai-disclosure) convention. It is not a well-known convention, but after some research, I judged it well-written and suitable for this project.

The convention is documented by `AI_DISCLOSURE.md` at the repository root, along with the default disclosure value. Disclosure is per-file, and any file can override the default it with an `SPDX-AI-Disclosure:` tag in a comment. The possible values for the tag are as follows:

| Value          | Means                                                                       |
|----------------|-----------------------------------------------------------------------------|
| `none`         | No AI involvement. Use when you want to positively assert human authorship. |
| `ai-assisted`  | Human-authored; AI edited, refined, or filled in boilerplate.               |
| `ai-generated` | AI-generated with human prompting and review.                               |
| `autonomous`   | AI-generated without meaningful human oversight.                            |

The default disclosure value is `ai-generated`. This will never change unless the project is rewritten, from scratch, without AI assistance. If it *does* change, you may consider the custody of the engine thoroughly compromised.

I explicitly forbid autonomous AI contributions, so there will never be an `autonomous` file in the repository.

## Automated Reporting

Whenever this documentation site is built, it also generates an AI disclosure report via `tool/disclosure.dart`. The tool allows me to assert that every file is accounted for; group files together to help understand progress towards goals; and exclude ineligible files from ownership concerns, such as assets, goldens, and source code managed by non-AI codegen tools.

### Disclosure

<Disclosure/>

### Exclusions

The following file groups have no provenance.

<Disclosure excluded/>
