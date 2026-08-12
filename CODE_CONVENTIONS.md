# Code Conventions

Conventions specific to this codebase, on top of what `dart format` and
`dart analyze` already enforce.

## Table of Contents

1. [Constructor Parameter Order](#1-constructor-parameter-order)
2. [Parameter Defaults](#2-parameter-defaults)
3. ["Blessed" Effect Targets](#3-blessed-effect-targets)
4. [The `cleanup` Parameter](#4-the-cleanup-parameter)
5. [No Mixins](#5-no-mixins)

## 1. Constructor Parameter Order

Own fields first, in declaration order, then forwarded `super.x` fields, in
their own established order. Don't interleave.

```dart
class ColliderNode extends SizedNode {
  Shape shape;
  int layer;
  int mask;

  ColliderNode({
    required this.shape,
    int? layer,
    int? mask,
    super.position,
    super.priority,
    // ...
  }) : layer = layer ?? -1,
       mask = mask ?? -1;
}
```

## 2. Parameter Defaults

Every parameter with a default is nullable, defaulted via `??` in the
constructor initializer list. Never use a default on the parameter itself.

```dart
// Right:
EffectNode({
  bool? cleanup,
  super.enabled,
  // ...
}) : cleanup = cleanup ?? false;

// Wrong: can't opt back into the default by passing null.
EffectNode({
  bool cleanup = false,
  // ...
});
```

## 3. "Blessed" Effect Targets

A builtin effect should only ever target one of a small, fixed set of "blessed" types,
whether that target is passed in explicitly or resolved automatically.

Currently, the blessed target types are:

- `TransformNode`
- `SizedNode`
- `Paint`


## 4. The `cleanup` Parameter

Any `bool` parameter that offers to self-`detach` a node once it "finishes" is always
named `cleanup`, and always defaults to `false`.

```dart
/// Whether to `detach` once finished. Defaults to false.
bool cleanup;

EffectNode({
  bool? cleanup,
  // ...
}) : cleanup = cleanup ?? false {
  onFinish(() {
    if (this.cleanup) detach();
  });
}
```

## 5. No Mixins

Avoid `mixin`. Prefer composition, or implementing an interface directly.
