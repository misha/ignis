import 'package:flutter/rendering.dart' show FlexFit;
import 'package:ignis/ignis.dart';

final class TestMeasurable with Measurable {
  final constraints = <LayoutConstraints>[];

  @override
  final Vector2 position;

  @override
  Anchor anchor;

  @override
  final Vector2 size;

  @override
  int flex;

  @override
  FlexFit fit;

  @override
  bool canResize;

  /// The constraints passed to the most recent [measure] call, or null if
  /// it hasn't been measured yet.
  LayoutConstraints? get lastConstraints => constraints.lastOrNull;

  TestMeasurable({
    Vector2? position,
    Anchor? anchor,
    Vector2? size,
    int? flex,
    FlexFit? fit,
    bool? canResize,
  }) : position = position ?? .zero(),
       anchor = anchor ?? .topLeft(),
       size = size ?? .zero(),
       flex = flex ?? 0,
       fit = fit ?? .loose,
       canResize = canResize ?? false;

  @override
  Vector2 measure(LayoutConstraints constraints) {
    this.constraints.add(constraints);
    return size;
  }
}
