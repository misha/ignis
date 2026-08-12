import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:ignis/src/extensions.dart';
import 'package:ignis/src/inputs/hover_input.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/node.dart';
import 'package:ignis/src/nodes/input_node.dart';
import 'package:ignis/src/scene_render_box.dart';

/// Resolves raw pointer events against a [Scene]'s tree and hands off to
/// whichever [InputNode]s claim them, per [InputNode.behavior].
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
    final point = event.localPosition.toVector2();
    _dispatch(point, (node) => node.register(event, box.globalToLocal));
  }

  void _handleHover(PointerHoverEvent event) {
    final point = event.localPosition.toVector2();
    final target = _dispatch(point, (node) => node is HoverInput ? .handled : .ignored);
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

  /// Walks [point]'s hit-test chain, offering each [InputNode] to [respond]
  /// until one is claimed by an opaque node.
  InputNode? _dispatch(Vector2 point, InputResult Function(InputNode) respond) {
    InputNode? result;

    for (final node in scene.node.hitTest(point).whereType<InputNode>()) {
      final response = respond(node);
      if (response == .ignored) continue;
      result ??= node;
      if (node.behavior == .opaque) break;
    }

    return result;
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
