---
title: Math
description: Mutable and immutable vectors, and which one you were handed.
lane: usage
category: concept
status: complete
---
<!-- SPDX-AI-Disclosure: none -->

## Types

Math types such as `Vector2`, `Matrix3`, and `Aabb2` come from Ignis' companion [`ivector_math`](https://pub.dev/packages/ivector_math) package.

`ivector_math` is a reimplementation of a subset of `vector_math` in which the mutability of an object is explicitly documented by its type.

<Warning>

  Ignis exports `ivector_math`. Do not add it to your `dependencies`.

</Warning>

## Mutability

Each type in `ivector_math` is immutable by default, but an additional mutable implementation is available with an `M` prefix. For example, `Vector2` is immutable, while `MVector2` is mutable and implements `Vector2`.

```dart
final position = Vector2(1, 2);
position.x = 3; // Compile-time error: `x` is final.

final velocity = MVector2(1, 2);
velocity.x = 3; // Sets x to 3.
```

Since the mutable type always implements the immutable type, you may use the prefix-free version throughout your code by default. When mutation is required, that requirement will now be documented explicitly through a type signature.

The library stays as close as practical to the original `vector_math` API, with a small number of additions and adjustments to support the immutable/mutable split.
