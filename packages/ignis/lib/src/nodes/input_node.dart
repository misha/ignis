// SPDX-AI-Disclosure: none

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:ignis/src/globals.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/spatial_node.dart';
import 'package:ignis/src/shape.dart';

/// A pointer hit area.
///
/// A node wanting more than one gesture just adds more input nodes at the
/// same spot. [priority] decides who's tried first. An event a node doesn't
/// apply to always falls through to the next one. Once a node does claim an
/// event, the search stops there unless [behavior] is [HitBehavior.translucent].
abstract class InputNode extends SpatialNode {
  Shape? _shape;

  /// The shape of the node's hit area.
  ///
  /// If not explicitly set, defaults to the parent's shape.
  @override
  Shape get shape => _shape ?? super.shape;

  /// Sets this collider's shape.
  ///
  /// If null, defaults back to the parent's shape.
  set shape(Shape? value) => _shape = value;

  /// Whether this node blocks nodes behind it once it claims an event.
  ///
  /// Defaults to [HitBehavior.opaque].
  HitBehavior behavior;

  InputNode({
    this._shape,
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
      final debug = Ignis.debug;
      if (!debug.draws(.input)) return;
      shape.draw(canvas, debug.paint);
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
    final adjusted = toLocal(point);

    switch (shape) {
      case Rectangle(:final size):
        if (size.x <= 0 || size.y <= 0) return false;

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
  /// TODO: Feels bad here. Maybe a SpatialNode concern?
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
