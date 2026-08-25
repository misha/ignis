import 'package:ignis/ignis.dart';

/// A [LayoutNode] whose reported size is controlled by [sizeToReturn], for
/// spying on the [LayoutConstraints] it's laid out with. Records every
/// [constrain] call in [layouts], and lays out any [LayoutNode]
/// children with the same constraints it receives.
final class TestLayoutNode extends LayoutNode {
  final layouts = <LayoutConstraints>[];
  Vector2 sizeToReturn;

  /// The constraints passed to the most recent [constrain] call, or
  /// null if it hasn't been laid out yet.
  LayoutConstraints? get lastConstraints => layouts.lastOrNull;

  TestLayoutNode({
    Vector2? sizeToReturn,
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.enabled,
    super.priority,
    super.children,
  }) : sizeToReturn = sizeToReturn ?? .zero;

  @override
  Vector2 constrain(LayoutConstraints constraints) {
    layouts.add(constraints);

    for (final child in layoutChildren.whereType<LayoutNode>()) {
      child.layout(constraints);
    }

    return sizeToReturn;
  }
}
