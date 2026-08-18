import 'package:flutter/gestures.dart';
import 'package:ignis/src/core.dart';
import 'package:ignis/src/extensions.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/input_node.dart';

/// A hit area that recognizes taps by delegating to a [TapGestureRecognizer].
class TapInput extends InputNode {
  /// How far the pointer may drift from where it landed before the tap
  /// cancels, in logical pixels. Defaults to [kTouchSlop], the same allowance
  /// Flutter's own tap gives.
  ///
  /// Pass null to let it drift any distance, which turns this into a press
  /// that lasts until it is released or the gesture arena takes it away.
  final double? slop;

  final onTapDown = Signal1<TapDownEvent>();
  final onTapUp = Signal1<TapUpEvent>();
  final onTap = Signal0();
  final onTapCancel = Signal0();

  bool _down = false;
  TapGestureRecognizer? _recognizer;

  /// Whether a pointer is currently down on this node.
  bool get isDown => _down;

  TapInput({
    required super.shape,
    this.slop = kTouchSlop,
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

    final recognizer = _recognizer = TapGestureRecognizer(
      preAcceptSlopTolerance: slop,
      postAcceptSlopTolerance: slop,
    );

    recognizer
      ..onTapDown = _handleDown
      ..onTapUp = _handleUp
      ..onTap = _handleTap
      ..onTapCancel = _handleCancel;

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

  void _handleDown(TapDownDetails details) {
    final scenePoint = details.localPosition.toVector2();
    _down = true;

    onTapDown.emit(
      TapDownEvent(
        scene: scenePoint,
        local: toLocal(scenePoint),
        details: details,
      ),
    );
  }

  void _handleUp(TapUpDetails details) {
    final scenePoint = details.localPosition.toVector2();
    _down = false;

    onTapUp.emit(
      TapUpEvent(
        scene: scenePoint,
        local: toLocal(scenePoint),
        details: details,
      ),
    );
  }

  void _handleTap() {
    onTap.emit();
  }

  void _handleCancel() {
    _down = false;
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
