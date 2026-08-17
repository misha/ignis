# Documentation Conventions

Conventions for everything a reader sees: the site under `docs/` and the doc comments `dart doc` publishes.

## Table of Contents

1. [House Style](#1-house-style)
2. [Lanes](#2-lanes)
3. [Categories](#3-categories)
4. [Status](#4-status)
5. [Page Shape](#5-page-shape)
6. [Register](#6-register)
7. [Boundaries](#7-boundaries)

## 1. House Style

- Address the reader as "you".
- Use dot shorthand in every sample, e.g. `shape: .circle(16)`, `padding: .all(4)`. Samples skip `const`.
- Use `<Warning>` for something that will bite you, `<Why>` for rationale, and `<Lineage from="Godot|Flame">` for where an idea came from.
- Anything else is ordinary prose.

## 2. Lanes

Every page declares a `lane` and serves exactly one reader.

| Lane        | Reader                           | Form                                 |
|-------------|----------------------------------|--------------------------------------|
| `usage`     | Building a game with Ignis       | Catalogs, demos, rules to follow     |
| `internals` | Understanding or extending Ignis | Principles, architecture, mechanisms |

```
"How do I make two things collide?"                         -> usage
"Why does the collision resolve the frame after I add it?"  -> internals
```

When the same topic appears in both lanes at different altitudes, cross-link them.

## 3. Categories

Every page declares a `category`. It fixes what the page owes its reader, and where it stops.

| Category   | Lane        | Owes                                        | Stops at                         |
|------------|-------------|---------------------------------------------|----------------------------------|
| `essay`    | `usage`     | An argument, and what it costs.             | Code.                            |
| `concept`  | `usage`     | A rule and what breaks when you ignore it.  | Enumerating API.                 |
| `system`   | `usage`     | A catalog of what you construct.            | Whatever `dart doc` says better. |
| `internal` | `internals` | A mechanism, walked through its own source. | Cataloguing.                     |

A page is finished when it has named its subject, shown it, stated its rule, and linked the source.

`usage` pages open with the demo, and prefer several small ones to one that does everything. `internals` pages carry no demos at all.

## 4. Status

Every page declares a `status`, and renders it.

| Status     | Means                                           |
|------------|-------------------------------------------------|
| `stub`     | Headings only. The topic exists and lives here. |
| `partial`  | Accurate, but below its category floor.         |
| `complete` | Meets its category floor.                       |

An incomplete page is not a reason to delay a deploy, drop a page, or omit a sidebar entry. A stub that names a topic beats an absent page.

## 5. Page Shape

Explain, then show. A page states everything it has to say, then runs its demos one after another without returning to prose.

A `system` page runs in this order.

1. The hero: `<Demo name="..." hero/>`, written *above* the lede, since it floats and only wraps what follows it.
2. The lede: one sentence naming the classes in `reference:` and what they do between them.
3. The dispatch: whatever the page does not own, sent to the page that does, in the same paragraph. This is what delineates the page's responsibility, so it goes before the reader has invested anything.
4. `## Overview`: the groups.
5. `### Known limitations`: the last group.
6. `## Examples`: one `###` per demo, in the order the Overview introduced them.

Groups are `###`, named as a noun, and open with one sentence whose main verb is the thing's job. "Is a", "is responsible for", "provides" and "handles" name a category instead of an action and are banned. A group whose lede cannot take a real verb is not a group.

An entry is a claim and its consequence: a declarative that is true on its own, then what it means for the reader. No bold lead-in - most entries open on an identifier, and that is anchor enough.

`### Known limitations` takes no lede, because a section defined by absence has no verb to give. Each entry is one clause of the form "You cannot X", with no consequence and no workaround attached. The section mirrors the `TODO`s in the source it documents: a resolved `TODO` removes an entry. Every `system` page carries the section, since an empty one still reports that somebody looked.

A demo documents itself, in its own source. It carries a heading and nothing else: no prose narrating it, and no comments between its `// demo on` and `// demo off` markers either. A demo is a handful of lines in isolation, so one that needs a comment to be read is a finding against the engine - a name, a default or a shape is wrong - and the fix belongs in `lib/`. Prose that narrates a demo is prose maintained in two places; a comment that explains one is a bug filed in the wrong place.

## 6. Register

Technical writing, not prose. Dry, precise, concise.

Those three are worth naming because each is *local*: verifiable one line at a time, against the source. Flow is global - it can only be checked by reading a whole section in order, it breaks at the seams between separately written parts, and it degrades invisibly, since every paragraph looks fine alone. A page written in parts, or generated, cannot hold flow. Do not ask it to.

- One fact per statement.
- Name identifiers and signatures, never paraphrases. `play(sheet:, row:, column:)`, not "how you leave a row".
- Fix the terminology. Frame, row, column and sheet mean one thing each, every time. Prose varies a word to avoid repeating it; here that is an error.
- No sentence fragments. Terseness does not excuse them.
- Numerals for counts: `4 animations`, a `14-frame` idle. Words only where the number is a determiner: "one frame at a time".
- The definite article only when the sentence supplies its own referent - "the current row", "the last frame of its row". An entry stands alone and cannot borrow "the image" from the entry above it.
- No antithesis unless the reader would genuinely have guessed wrong. "X rather than Y" and "not Z" presuppose a belief; where the alternative is invented, the reader is corrected for something they never thought. It is the loudest tell in generated text.

## 7. Boundaries

What a page leaves out is as fixed as what it includes.

- Defaults. `dart doc` states them, and a second copy drifts.
- The contents of an error message. That a call throws is the fact worth having; the string is the exception's business.
- Anything another page owns. Link to it. Tie-breaking is part of what `priority` means, so it belongs to the page that defines `priority`.
- A workaround for a limitation. A documented workaround becomes the recommended path, and then constrains the fix.
- Internal state changes, where an observable behavior says it better. "A sprite finishes once" over "`play` clears the flag".
- A `<Why>` without a decision behind it. Where the honest answer is "not built yet", the content is a limitation, and it goes in `### Known limitations`. Rationale invented to cover a gap reads as authoritative and has nothing in the source to check it against.
