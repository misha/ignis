import 'package:ignis/ignis.dart';

final class TestMeasurable with Measurable {
  final constraints = <LayoutConstraints>[];

  @override
  final MVector2 position;

  @override
  Anchor anchor;

  @override
  final Vector2 size;

  @override
  LayoutFlex flex;

  /// The constraints passed to the most recent [measure] call, or null if
  /// it hasn't been measured yet.
  LayoutConstraints? get lastConstraints => constraints.lastOrNull;

  TestMeasurable({
    MVector2? position,
    Anchor? anchor,
    Vector2? size,
    LayoutFlex? flex,
  }) : position = position ?? .zero(),
       anchor = anchor ?? .topLeft,
       size = size ?? .zero,
       flex = flex ?? .none;

  @override
  Vector2 measure(LayoutConstraints constraints) {
    this.constraints.add(constraints);
    return size;
  }
}
