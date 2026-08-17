# Design Conventions

Conventions for how Ignis and its documentation look.

## Table of Contents

1. [Colors](#1-colors)
2. [Roles](#2-roles)
3. [Type](#3-type)
4. [Interactivity](#4-interactivity)
5. [Assets](#5-assets)

## 1. Colors

Every color comes from the flame in `ignis.png`, sampled from its painted pixels.

|           |       |                                  |
|-----------|-------|----------------------------------|
| `#780E04` | deep  | the darkest ember                |
| `#A32C0D` | core  | the largest mass in the painting |
| `#B65A18` | burnt |                                  |
| `#C36E21` | flame |                                  |
| `#C78F30` | amber |                                  |
| `#C99F4F` | gold  |                                  |
| `#CDC07B` | pale  | the hottest highlight            |

## 2. Roles

Dark is designed. Light is derived from it and checked for contrast, not hand-tuned.

| Role         | Use                                                            |
|--------------|----------------------------------------------------------------|
| `background` | the page                                                       |
| `surface`    | anything sitting on the page: code, demos, callouts, banners   |
| `border`     | hairlines, and nothing else                                    |
| `text`       | prose                                                          |
| `headings`   | headings                                                       |
| `muted`      | captions, status, labels, punctuation                          |
| `primary`    | links, active navigation, focus                                |
| `primary-hi` | hover                                                          |
| `brand`      | the mark alone. Never text - it fails contrast on both grounds |

## 3. Type

|                      |                           |
|----------------------|---------------------------|
| IM FELL Great Primer | the wordmark and headings |
| EB Garamond          | prose                     |
| iA Writer Mono       | code                      |

## 4. Interactivity

Motion is a cue, not decoration. If an animation is not telling the reader that something changed, it should not be there.

Honor `prefers-reduced-motion`. Anything that moves on its own must have a still state that is complete on its own.

## 5. Assets

Demos share one small set of assets rather than each bringing their own. Adding to the set needs a demo that cannot be built from what is already there.

The mark is a scan of a painting. It is scaled and re-encoded, never redrawn, recolored, or cropped, and it is credited to Mewyn wherever it appears.
