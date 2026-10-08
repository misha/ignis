// SPDX-AI-Disclosure: none

import 'package:flutter/gestures.dart';
import 'package:ignis/src/core.dart';
import 'package:ignis/src/extensions.dart';
import 'package:ignis/src/inputs/nodes/input_node.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/message.dart';

/// A hit area that recognizes taps by delegating to a [TapGestureRecognizer].
class TapInput extends InputNode {
  /// How far the pointer may drift from where it landed before the tap
  /// cancels, in logical pixels. Defaults to [kTouchSlop], the same allowance
  /// Flutter's own tap gives.
  ///
  /// Pass null to let it drift any distance, which turns this into a press
  /// that lasts until it is released or the gesture arena takes it away.
  final double? slop;

  /// Whether a cancelled tap should also manufacture and emit a [TapUp],
  /// built from the position the pointer went down at.
  ///
  /// If enabled, [TapUp] is emitted immediately *after* [TapCancel].
  ///
  /// Defaults to `false`.
  final bool upOnCancel;

  TapDownDetails? _down;
  TapGestureRecognizer? _recognizer;

  /// Whether a pointer is currently down on this node.
  bool get isDown => _down != null;

  TapInput({
    super.shape,
    this.slop = kTouchSlop,
    bool? upOnCancel,
    super.behavior,
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.enabled,
    super.priority,
    super.children,
  }) : upOnCancel = upOnCancel ?? false;

  @override
  void process(Message message) {
    super.process(message);

    switch (message) {
      case Build():
        final recognizer = _recognizer = TapGestureRecognizer(
          preAcceptSlopTolerance: slop,
          postAcceptSlopTolerance: slop,
        );

        recognizer
          ..onTapDown = _handleDown
          ..onTapUp = _handleUp
          ..onTap = _handleTap
          ..onTapCancel = _handleCancel;

      case Destroy():
        _recognizer?.dispose();
        _recognizer = null;
    }
  }

  @override
  InputResult register(PointerDownEvent event, _) {
    _recognizer!.addPointer(event);
    return .handled;
  }

  void _handleDown(TapDownDetails details) {
    final scenePoint = details.localPosition.toVector2();
    _down = details;

    parent?.post(
      TapDown(
        this,
        scene: scenePoint,
        local: toLocal(scenePoint),
        details: details,
      ),
    );
  }

  void _handleUp(TapUpDetails details) {
    final scenePoint = details.localPosition.toVector2();
    _down = null;

    parent?.post(
      TapUp(
        this,
        scene: scenePoint,
        local: toLocal(scenePoint),
        details: details,
      ),
    );
  }

  void _handleTap() {
    parent?.post(Tap(this));
  }

  void _handleCancel() {
    final down = _down;
    _down = null;
    parent?.post(TapCancel(this));

    if (upOnCancel) {
      final scenePoint = down!.localPosition.toVector2();

      parent?.post(
        TapUp(
          this,
          scene: scenePoint,
          local: toLocal(scenePoint),
          details: TapUpDetails(
            globalPosition: down.globalPosition,
            localPosition: down.localPosition,
            kind: down.kind ?? .unknown,
          ),
        ),
      );
    }
  }
}

final class TapDown extends Message {
  final TapInput input;

  /// This pointer's position in scene (world) space.
  final Vector2 scene;

  /// This pointer's position in the receiving node's local space.
  final Vector2 local;

  /// Flutter's own details for this event.
  final TapDownDetails details;

  const TapDown(
    this.input, {
    required this.scene,
    required this.local,
    required this.details,
  });
}

final class TapUp extends Message {
  final TapInput input;

  /// This pointer's position in scene (world) space.
  final Vector2 scene;

  /// This pointer's position in the receiving node's local space.
  final Vector2 local;

  /// Flutter's own details for this event.
  final TapUpDetails details;

  const TapUp(
    this.input, {
    required this.scene,
    required this.local,
    required this.details,
  });
}

/// Emitted when [input] recognizes a tap.
final class Tap extends Message {
  final TapInput input;

  const Tap(this.input);
}

/// Emitted when [input]'s tap is cancelled.
final class TapCancel extends Message {
  final TapInput input;

  const TapCancel(this.input);
}
