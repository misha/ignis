# Engine Conventions

Conventions for writing engine code, on top of what `dart format` and `dart analyze` already enforce.

## Table of Contents

1. [Node Constructors](#1-node-constructors)
2. [Parameter Defaults](#2-parameter-defaults)
3. [The `cleanup` Parameter](#3-the-cleanup-parameter)
4. [No Mixins](#4-no-mixins)
5. [Effect Controller Constructors](#5-effect-controller-constructors)

## 1. Node Constructors

Node constructors always use named parameters, listing their own fields first in declaration order, then forwarded `super.x` fields in their established order. Don't interleave.

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

Every parameter with a default is nullable, defaulted via `??` in the constructor initializer list. Never use a default on the parameter itself.

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

## 3. The `cleanup` Parameter

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

## 4. No Mixins

Avoid `mixin`. Prefer composition, or implementing an interface directly.

## 5. Effect Controller Constructors

Effect controller constructors always use positional parameters (`[...]`), not named (`{...}`). 

```dart
class DurationEffectController extends EffectController {
  DurationEffectController(this.duration, [Curve? curve]) //
    : curve = curve ?? Curves.linear;
}
```
