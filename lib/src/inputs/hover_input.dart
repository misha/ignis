import 'package:flutter/gestures.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/input_node.dart';
import 'package:ignis/src/signal.dart';

/// A hit area that recognizes mouse hover.
class HoverInput extends InputNode {
  final onHoverEnter = Signal1<HoverEvent>();
  final onHoverExit = Signal1<HoverEvent>();

  HoverInput({
    required super.shape,
    super.position,
    super.scale,
    super.angle,
    super.size,
    super.anchor,
    super.enabled,
    super.priority,
    super.children,
  });
}

final class HoverEvent {
  /// This pointer's position in scene (world) space.
  final Vector2 scene;

  /// This pointer's position in the receiving node's local space.
  final Vector2 local;

  /// The raw pointer event this was built from.
  final PointerEvent source;

  const HoverEvent({
    required this.scene,
    required this.local,
    required this.source,
  });
}
