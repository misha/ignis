import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:ignis/src/math.dart';

/// Data delivered to an [InputNode] pointer signal.
class PointerInfo {
  /// This pointer's platform-assigned id.
  final int id;

  /// The device that produced this pointer.
  final PointerDeviceKind kind;

  /// This pointer's position in scene (world) space.
  final Vector2 scene;

  /// This pointer's position in the receiving node's local space.
  final Vector2 local;

  const PointerInfo({
    required this.id,
    required this.kind,
    required this.scene,
    required this.local,
  });

  @override
  String toString() => '$id|$scene|${kind.name}';
}
