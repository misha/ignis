import 'package:flutter/gestures.dart';
import 'package:ignis/src/extensions.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/input_node.dart';
import 'package:ignis/src/signal.dart';

/// A hit area that recognizes drags by delegating to an [ImmediateMultiDragGestureRecognizer].
class DragInput extends InputNode {
  final onDragStart = Signal1<DragStartEvent>();
  final onDragUpdate = Signal1<DragUpdateEvent>();
  final onDragEnd = Signal1<DragEndEvent>();
  final onDragCancel = Signal0();

  ImmediateMultiDragGestureRecognizer? _recognizer;
  Vector2? _pendingStart;
  Offset Function(Offset)? _pendingGlobalToLocal;

  DragInput({
    required super.shape,
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.enabled,
    super.priority,
    super.children,
  }) {
    onMount(() {
      _recognizer = .new()..onStart = _handleStart;
    });

    onUnmount(() {
      _recognizer?.dispose();
      _recognizer = null;
    });
  }

  @override
  void register(PointerDownEvent event, Offset Function(Offset) globalToLocal) {
    _pendingStart = event.localPosition.toVector2();
    _pendingGlobalToLocal = globalToLocal;
    _recognizer!.addPointer(event);
  }

  Drag? _handleStart(Offset globalPosition) {
    final scenePoint = _pendingStart!;
    final globalToLocal = _pendingGlobalToLocal!;
    _pendingStart = null;
    _pendingGlobalToLocal = null;

    onDragStart.emit(
      DragStartEvent(
        scene: scenePoint,
        local: toLocal(scenePoint),
      ),
    );

    return _NodeDrag(this, globalToLocal);
  }
}

class _NodeDrag extends Drag {
  final DragInput node;
  final Offset Function(Offset) globalToLocal;
  Vector2? last;

  _NodeDrag(this.node, this.globalToLocal);

  @override
  void update(DragUpdateDetails details) {
    // DragUpdateDetails.localPosition is unreliable: MultiDragGestureRecognizer
    // never threads a transformed position through it, so it's just the raw
    // global position again. Convert it ourselves instead.
    final scenePoint = globalToLocal(details.globalPosition).toVector2();
    final delta = last == null ? Vector2.zero() : scenePoint - last!;
    last = scenePoint;

    node.onDragUpdate.emit(
      DragUpdateEvent(
        scene: scenePoint,
        local: node.toLocal(scenePoint),
        delta: delta,
        details: details,
      ),
    );
  }

  @override
  void end(DragEndDetails details) {
    node.onDragEnd.emit(DragEndEvent(details: details));
  }

  @override
  void cancel() {
    node.onDragCancel.emit();
  }
}

final class DragStartEvent {
  /// This pointer's position in scene (world) space.
  final Vector2 scene;

  /// This pointer's position in the receiving node's local space.
  final Vector2 local;

  const DragStartEvent({
    required this.scene,
    required this.local,
  });
}

final class DragUpdateEvent {
  /// This pointer's position in scene (world) space.
  final Vector2 scene;

  /// This pointer's position in the receiving node's local space.
  final Vector2 local;

  /// How far the pointer moved since the last [DragUpdateEvent] (or since
  /// [DragStartEvent], for the first one), in scene space.
  final Vector2 delta;

  /// Flutter's own details for this event.
  final DragUpdateDetails details;

  const DragUpdateEvent({
    required this.scene,
    required this.local,
    required this.delta,
    required this.details,
  });
}

final class DragEndEvent {
  /// Flutter's own details for this event.
  final DragEndDetails details;

  const DragEndEvent({
    required this.details,
  });
}
