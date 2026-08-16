import 'package:flutter/gestures.dart';
import 'package:ignis/src/core.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/input_node.dart';

/// A hit area that recognizes mouse hover.
class HoverInput extends InputNode {
  bool _hovering = false;

  /// Whether a pointer is currently hovering this node.
  bool get isHovering => _hovering;

  /// Emitted when a pointer starts hovering this node.
  final onHoverEnter = Signal1<HoverEvent>();

  /// Emitted when a pointer stops hovering this node.
  final onHoverExit = Signal1<HoverEvent>();

  HoverInput({
    required super.shape,
    super.behavior,
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.enabled,
    super.priority,
    super.children,
  });

  @override
  void build() {
    super.build();
    onHoverEnter((_) => _hovering = true);
    onHoverExit((_) => _hovering = false);
  }
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
