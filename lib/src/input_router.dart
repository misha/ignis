import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:ignis/src/extensions.dart';
import 'package:ignis/src/inputs/hover_input.dart';
import 'package:ignis/src/node.dart';
import 'package:ignis/src/nodes/input_node.dart';
import 'package:ignis/src/scene_render_box.dart';

/// Resolves raw pointer events against a [Scene]'s tree and hands off to
/// whichever gesture recognizer the hit [InputNode] owns.
///
/// TODO: Refactor this. It currently has two distinct jobs, routing and hover.
@internal
class InputRouter {
  final SceneRenderBox box;
  Scene get scene => box.scene;

  final Map<int, InputNode> _hovered = {};

  InputRouter(this.box);

  void handle(PointerEvent event) {
    switch (event) {
      case PointerDownEvent():
        _handleDown(event);

      case PointerHoverEvent():
        _handleHover(event);

      default:
    }
  }

  void _handleDown(PointerDownEvent event) {
    final hit = scene.node.hitTest(event.localPosition.toVector2());
    if (hit is InputNode) hit.register(event, box.globalToLocal);
  }

  void _handleHover(PointerHoverEvent event) {
    final hit = scene.node.hitTest(event.localPosition.toVector2());
    final target = hit is InputNode ? hit : null;
    final previous = _hovered[event.pointer];
    if (identical(target, previous)) return;
    if (previous is HoverInput) previous.onHoverExit.emit(_wrap(previous, event));

    switch (target) {
      case InputNode():
        _hovered[event.pointer] = target;
        if (target is HoverInput) target.onHoverEnter.emit(_wrap(target, event));

      case null:
        _hovered.remove(event.pointer);
    }
  }

  static HoverEvent _wrap(InputNode node, PointerEvent event) {
    final scenePoint = event.localPosition.toVector2();
    return HoverEvent(
      scene: scenePoint,
      local: node.toLocal(scenePoint),
      source: event,
    );
  }
}
