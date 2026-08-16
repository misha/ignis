import 'package:flutter/gestures.dart';
import 'package:ignis/src/core.dart';
import 'package:ignis/src/extensions.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/input_node.dart';

/// A hit area that recognizes taps by delegating to a [MultiTapGestureRecognizer].
class TapInput extends InputNode {
  final onTapDown = Signal1<TapDownEvent>();
  final onTapUp = Signal1<TapUpEvent>();
  final onTap = Signal0();
  final onTapCancel = Signal0();

  MultiTapGestureRecognizer? _recognizer;

  TapInput({
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
    final recognizer = _recognizer = MultiTapGestureRecognizer()
      ..onTapDown = _handleTapDown
      ..onTapUp = _handleTapUp
      ..onTap = _handleTap
      ..onTapCancel = _handleTapCancel;

    trash(() {
      recognizer.dispose();
      _recognizer = null;
    });
  }

  @override
  InputResult register(PointerDownEvent event, _) {
    _recognizer!.addPointer(event);
    return .handled;
  }

  void _handleTapDown(int pointer, TapDownDetails details) {
    final scenePoint = details.localPosition.toVector2();

    onTapDown.emit(
      TapDownEvent(
        scene: scenePoint,
        local: toLocal(scenePoint),
        details: details,
      ),
    );
  }

  void _handleTapUp(int pointer, TapUpDetails details) {
    final scenePoint = details.localPosition.toVector2();

    onTapUp.emit(
      TapUpEvent(
        scene: scenePoint,
        local: toLocal(scenePoint),
        details: details,
      ),
    );
  }

  void _handleTap(int pointer) {
    onTap.emit();
  }

  void _handleTapCancel(int pointer) {
    onTapCancel.emit();
  }
}

final class TapDownEvent {
  /// This pointer's position in scene (world) space.
  final Vector2 scene;

  /// This pointer's position in the receiving node's local space.
  final Vector2 local;

  /// Flutter's own details for this event.
  final TapDownDetails details;

  const TapDownEvent({
    required this.scene,
    required this.local,
    required this.details,
  });
}

final class TapUpEvent {
  /// This pointer's position in scene (world) space.
  final Vector2 scene;

  /// This pointer's position in the receiving node's local space.
  final Vector2 local;

  /// Flutter's own details for this event.
  final TapUpDetails details;

  const TapUpEvent({
    required this.scene,
    required this.local,
    required this.details,
  });
}
