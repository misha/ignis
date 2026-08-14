import 'package:ignis/ignis.dart';

final class TestLayoutItem implements LayoutItem {
  final constraints = <LayoutConstraints>[];

  @override
  final MVector2 position;

  @override
  Anchor anchor;

  @override
  final Vector2 size;

  @override
  Vector2 scale;

  @override
  double get width => size.x;

  @override
  double get height => size.y;

  @override
  LayoutFlex flex;

  /// The constraints passed to the most recent [measure] call, or null if
  /// it hasn't been measured yet.
  LayoutConstraints? get lastConstraints => constraints.lastOrNull;

  TestLayoutItem({
    MVector2? position,
    Anchor? anchor,
    Vector2? size,
    Vector2? scale,
    LayoutFlex? flex,
  }) : position = position ?? .zero(),
       anchor = anchor ?? .topLeft,
       size = size ?? .zero,
       scale = scale ?? .all(1),
       flex = flex ?? .none;

  @override
  void layout(LayoutConstraints constraints) => this.constraints.add(constraints);
}
