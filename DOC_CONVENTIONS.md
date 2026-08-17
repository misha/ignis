# Documentation Conventions

Conventions for everything a reader sees: the site under `docs/` and the doc comments `dart doc` publishes.

## Table of Contents

1. [House Style](#1-house-style)
2. [Lanes](#2-lanes)
3. [Categories](#3-categories)
4. [Status](#4-status)
5. [Page Shape](#5-page-shape)

## 1. House Style

- Address the reader as "you".
- Headings are Title Case: every word capitalized except articles, conjunctions and prepositions, as in `## Getting It Wrong` and `## Differences from Flame`. The one exception is a catalog's per-demo `###`, which stays sentence case.
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

A `usage` page is a text summary of the major features, followed by a catalog of examples.

The summary is prose. The catalog is one `###` per demo, run one after another, and it is as long as the feature set is wide.
