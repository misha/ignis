# Engine Conventions

Conventions for writing engine code, on top of what `dart format` and `dart analyze` already enforce.

## Table of Contents

1. [Node Constructors](#1-node-constructors)
2. [Parameter Defaults](#2-parameter-defaults)
3. [The `cleanup` Parameter](#3-the-cleanup-parameter)
4. [No Mixins](#4-no-mixins)
5. [Effect Controller Constructors](#5-effect-controller-constructors)
6. [Servers](#6-servers)
7. [Engines](#7-engines)

## 1. Node Constructors

Node constructors always use named parameters, listing their own fields first in declaration order, then forwarded `super.x` fields in their established order. Don't interleave.

```dart
class ColliderNode extends SpatialNode {
  Shape? _shape;
  int layer;
  int mask;

  ColliderNode({
    Shape? shape,
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

## 6. Servers

A subsystem's logic lives outside the tree in a `Server`. The abstraction exists to reify the patterns of integration. There are currently two kinds of servers:

- `SteppedServer` is driven by a `process(dt)` method.
- `EventServer` is driven by a `dispatch(event)` method.

`SteppedServer`s usually have a *host node* in the tree responsible for providing the server to the subtree and processing it on tick:

```dart
class CollisionArenaNode extends Node {
  final CollisionArena arena;

  CollisionArenaNode({
    CollisionArena? arena,
    // ...
  }) : arena = arena ?? CollisionArena() {
    provide<CollisionArena>(this.arena);
  }

  @override
  void build() {
    super.build();
    tick(arena.process);
  }
}
```

`EventServer`s live wherever they are scoped:

- For the global scope, the server is declared on `Ignis`.
- For the scene scope, the server is declared on `SceneRenderBox`.
- For the node scope, the server is declared by a host node, like `SteppedServer`s.

## 7. Engines

A collection of related algorithms is an `Engine`. It knows nothing of nodes or signals, and is injected where it is used, with a `Standard` implementation as the default. Its primary purpose is to create a logical shape around complex logic for testability and benchmarking purposes.

```dart
final class CollisionArena extends SteppedServer {
  final IntersectionEngine engine;

  CollisionArena({
    IntersectionEngine? engine,
  }) : engine = engine ?? const StandardIntersectionEngine();
}
```
