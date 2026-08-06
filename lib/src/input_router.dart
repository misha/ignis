import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:ignis/src/extensions.dart';
import 'package:ignis/src/node.dart';
import 'package:ignis/src/nodes/input_node.dart';
import 'package:ignis/src/pointer_info.dart';

@internal
class InputRouter {
  final Scene scene;

  final Map<int, InputNode> _captured = {};
  final Map<int, InputNode> _hovered = {};

  InputRouter(this.scene);

  void handle(PointerEvent event) {
    switch (event) {
      case PointerDownEvent():
        _handleDown(event);

      case PointerMoveEvent():
        _handleMove(event);

      case PointerUpEvent():
        _handleUp(event);

      case PointerCancelEvent():
        _handleCancel(event);

      case PointerHoverEvent():
        _handleHover(event);
    }
  }

  void _handleDown(PointerDownEvent event) {
    final point = event.localPosition.toVector2();
    final hit = scene.node.hitTest(point);
    if (hit is! InputNode) return;
    _captured[event.pointer] = hit;
    hit.onPointerDown.emit(wrap(hit, event));
  }

  void _handleMove(PointerMoveEvent event) {
    final captured = _captured[event.pointer];
    if (captured == null) return;
    captured.onPointerMove.emit(wrap(captured, event));
  }

  void _handleUp(PointerUpEvent event) {
    final captured = _captured.remove(event.pointer);
    if (captured == null) return;
    captured.onPointerUp.emit(wrap(captured, event));
  }

  void _handleCancel(PointerCancelEvent event) {
    final captured = _captured.remove(event.pointer);
    if (captured == null) return;
    captured.onPointerCancel.emit(wrap(captured, event));
  }

  void _handleHover(PointerHoverEvent event) {
    final point = event.localPosition.toVector2();
    final hit = scene.node.hitTest(point);
    final previous = _hovered[event.pointer];
    if (identical(hit, previous)) return;
    if (previous != null) previous.onPointerExit.emit(wrap(previous, event));

    switch (hit) {
      case InputNode():
        _hovered[event.pointer] = hit;
        hit.onPointerEnter.emit(wrap(hit, event));

      case null:
        _hovered.remove(event.pointer);
    }
  }

  @visibleForTesting
  static PointerInfo wrap(InputNode node, PointerEvent event) {
    // TODO: Make these lazy.
    final scenePoint = event.localPosition.toVector2();
    final transform = node.absoluteTransform()..mutate().invert();

    return PointerInfo(
      id: event.pointer,
      kind: event.kind,
      scene: scenePoint,
      local: scenePoint.transformWith(transform),
    );
  }
}
