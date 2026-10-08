// SPDX-AI-Disclosure: none

// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/gestures.dart';
import 'package:ignis/src/core.dart';
import 'package:ignis/src/extensions.dart';
import 'package:ignis/src/inputs/nodes/input_node.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/message.dart';

/// A hit area that recognizes drags by delegating to an [ImmediateMultiDragGestureRecognizer].
class DragInput extends InputNode {
  bool _dragging = false;

  /// Whether this node is currently being dragged.
  bool get isDragging => _dragging;

  /// Whether a cancelled drag should also manufacture and emit a [DragEnd],
  /// built from the last known drag position.
  ///
  /// If enabled, [DragEnd] is emitted immediately *after* [DragCancel].
  ///
  /// Defaults to `false`.
  final bool endOnCancel;

  ImmediateMultiDragGestureRecognizer? _recognizer;
  Vector2? _pendingStart;
  Offset Function(Offset)? _pendingGlobalToLocal;
  _NodeDrag? _drag;

  DragInput({
    super.shape,
    bool? endOnCancel,
    super.behavior,
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.enabled,
    super.priority,
    super.children,
  }) : endOnCancel = endOnCancel ?? false;

  @override
  void process(Message message) {
    super.process(message);

    switch (message) {
      case Build():
        _recognizer = ImmediateMultiDragGestureRecognizer()..onStart = _handleStart;

      case Destroy():
        _drag?.cancel();
        _recognizer?.dispose();
        _recognizer = null;
    }
  }

  @override
  InputResult register(PointerDownEvent event, Offset Function(Offset) globalToLocal) {
    _pendingStart = event.localPosition.toVector2();
    _pendingGlobalToLocal = globalToLocal;
    _recognizer!.addPointer(event);
    return .handled;
  }

  Drag? _handleStart(Offset globalPosition) {
    final scenePosition = _pendingStart!;
    final globalToLocal = _pendingGlobalToLocal!;
    _pendingStart = null;
    _pendingGlobalToLocal = null;
    _dragging = true;

    parent?.post(
      DragStart(
        this,
        scene: scenePosition,
        local: toLocal(scenePosition),
      ),
    );

    return _drag = _NodeDrag(
      this,
      globalToLocal,
      globalToLocal(globalPosition).toVector2(),
    );
  }
}

class _NodeDrag extends Drag {
  final DragInput node;
  final Offset Function(Offset) globalToLocal;
  Vector2 lastScenePosition;
  Offset lastGlobalOffset = .zero;

  _NodeDrag(this.node, this.globalToLocal, this.lastScenePosition);

  @override
  void update(DragUpdateDetails details) {
    // DragUpdateDetails.localPosition is unreliable: MultiDragGestureRecognizer
    // never threads a transformed position through it, so it's just the raw
    // global position again. Convert it ourselves instead.
    // TODO: Seems unlikely this kluge is required. Reread the Flutter source.
    final scenePosition = globalToLocal(details.globalPosition).toVector2();
    final delta = scenePosition - lastScenePosition;
    lastScenePosition = scenePosition;
    lastGlobalOffset = details.globalPosition;

    node.parent?.post(
      DragUpdate(
        node,
        scene: scenePosition,
        local: node.toLocal(scenePosition),
        delta: delta,
        details: details,
      ),
    );
  }

  @override
  void end(DragEndDetails details) {
    node._drag = null;
    node._dragging = false;

    node.parent?.post(
      DragEnd(
        node,
        details: details,
      ),
    );
  }

  @override
  void cancel() {
    node._drag = null;
    node._dragging = false;
    node.parent?.post(DragCancel(node));

    if (node.endOnCancel) {
      node.parent?.post(
        DragEnd(
          node,
          details: DragEndDetails(
            globalPosition: lastGlobalOffset,
          ),
        ),
      );
    }
  }
}

final class DragStart extends Message {
  final DragInput input;

  /// This pointer's position in scene (world) space.
  final Vector2 scene;

  /// This pointer's position in the receiving node's local space.
  final Vector2 local;

  const DragStart(
    this.input, {
    required this.scene,
    required this.local,
  });
}

final class DragUpdate extends Message {
  final DragInput input;

  /// This pointer's position in scene (world) space.
  final Vector2 scene;

  /// This pointer's position in the receiving node's local space.
  final Vector2 local;

  /// How far the pointer moved since the last [DragUpdate] (or since
  /// [DragStart], for the first one), in scene space.
  final Vector2 delta;

  /// Flutter's own details for this event.
  final DragUpdateDetails details;

  const DragUpdate(
    this.input, {
    required this.scene,
    required this.local,
    required this.delta,
    required this.details,
  });
}

final class DragEnd extends Message {
  final DragInput input;

  /// Flutter's own details for this event.
  final DragEndDetails details;

  const DragEnd(
    this.input, {
    required this.details,
  });
}

/// Emitted when [input]'s drag is cancelled.
final class DragCancel extends Message {
  final DragInput input;

  const DragCancel(this.input);
}
