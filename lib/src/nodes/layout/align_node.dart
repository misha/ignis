import 'package:ignis/src/anchor.dart';
import 'package:ignis/src/layout_constraints.dart';
import 'package:ignis/src/layout_engine.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/layout_node.dart';

/// Aligns each child within the space this node claims, with every child
/// sharing this node's [alignment].
///
/// Roughly equivalent to Flutter's `Align` with a `Stack` inside.
class AlignNode extends LayoutNode {
  /// Where each child sits within the space this node claims, as a fraction
  /// of the leftover room in each axis. Defaults to `center`.
  Anchor alignment;

  AlignNode({
    Anchor? alignment,
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.enabled,
    super.priority,
    super.children,
  }) : alignment = alignment ?? .center();

  @override
  Vector2 constrain(LayoutConstraints constraints) {
    // TODO: Cache this.
    final items = children.whereType<Measurable>().toList(growable: false);

    return LayoutEngine.stack(
      items: items,
      childConstraints: constraints.loosen(),
      computeSelfSize: (count, largest) => count == 0
          ? constraints.smallest
          : constraints.satisfy(
              .new(
                constraints.hasBoundedWidth ? double.infinity : largest.x,
                constraints.hasBoundedHeight ? double.infinity : largest.y,
              ),
            ),
      computeOffset: (selfSize, childSize) => .new(
        (selfSize.x - childSize.x) * alignment.x,
        (selfSize.y - childSize.y) * alignment.y,
      ),
    );
  }
}
