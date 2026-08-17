import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:ignis/src/debug.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/sized_node.dart';
import 'package:ignis/src/shape.dart';

/// A pointer hit area.
///
/// A node wanting more than one gesture just adds more input nodes at the
/// same spot. [priority] decides who's tried first. An event a node doesn't
/// apply to always falls through to the next one. Once a node does claim an
/// event, the search stops there unless [behavior] is [HitBehavior.translucent].
abstract class InputNode extends SizedNode {
  /// The shape of the node's hit area.
  Shape shape;

  @override
  Vector2 get size => shape.size;

  /// Whether this node blocks nodes behind it once it claims an event.
  ///
  /// Defaults to [HitBehavior.opaque].
  HitBehavior behavior;

  InputNode({
    required this.shape,
    HitBehavior? behavior,
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.enabled,
    super.priority,
    super.children,
  }) : behavior = behavior ?? .opaque;

  @override
  void build() {
    super.build();

    debugDraw((canvas) {
      switch (shape) {
        case Circle():
          canvas.drawOval(shape.rect(), DEBUG_INPUT_PAINT);

        case Rectangle():
          canvas.drawRect(shape.rect(), DEBUG_INPUT_PAINT);
      }
    });
  }

  /// Registers [event] with this node's gesture recognizer, if it has one.
  ///
  /// [globalToLocal] converts a global (window) position into scene space.
  /// Recognizers whose details don't carry a correctly-transformed position
  /// of their own (namely drag) need it to stay accurate when scaled.
  @internal
  InputResult register(PointerDownEvent event, Offset Function(Offset) globalToLocal) {
    return .ignored;
  }

  @override
  bool containsPoint(Vector2 point) {
    final local = toLocal(point);
    final adjusted = Vector2(
      local.x + anchor.x * width,
      local.y + anchor.y * height,
    );

    switch (shape) {
      case Rectangle(:final size):
        return adjusted.x >= 0 && //
            adjusted.x <= size.x &&
            adjusted.y >= 0 &&
            adjusted.y <= size.y;

      case Circle(:final radius):
        final dx = adjusted.x - radius;
        final dy = adjusted.y - radius;
        return dx * dx + dy * dy <= radius * radius;
    }
  }

  /// Converts [scenePoint] into this node's local space.
  ///
  /// TODO: Feels bad here. Maybe a SizedNode concern?
  Vector2 toLocal(Vector2 scenePoint) {
    final inverse = absoluteTransform()..invert();
    return scenePoint.transformed(inverse);
  }
}

/// Governs whether an [InputNode] blocks nodes behind it once it claims an
/// event, or lets the search continue regardless.
enum HitBehavior {
  /// Stops the search here once this node claims an event.
  opaque,

  /// Keeps searching past this node even after it claims an event.
  translucent,
}

/// Whether an [InputNode] claimed an event routed to it.
enum InputResult {
  /// This node doesn't apply to the event; it falls through to the next one.
  ignored,

  /// This node claimed the event.
  handled,
}
