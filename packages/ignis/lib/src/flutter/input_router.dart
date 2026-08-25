// SPDX-AI-Disclosure: ai-assisted

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:ignis/src/core.dart';
import 'package:ignis/src/extensions.dart';
import 'package:ignis/src/flutter/scene_render_box.dart';
import 'package:ignis/src/inputs/nodes/hover_input.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/input_node.dart';

/// Resolves raw pointer events against a [Scene]'s tree and hands off to
/// whichever [InputNode]s claim them, per [InputNode.behavior].
@internal
class InputRouter {
  final SceneRenderBox box;
  Scene get scene => box.scene;

  final Map<int, _Hover> _hovered = {};

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
    if (identical(target, previous?.node)) return;
    if (previous != null) _exit(event.pointer, _wrap(previous.node, event));
    if (target != null) _enter(event.pointer, target, event);
  }

  /// Records [target] as [pointer]'s hover, emitting `onHoverEnter`.
  void _enter(int pointer, InputNode target, PointerHoverEvent event) {
    final hover = _wrap(target, event);

    _hovered[pointer] = _Hover(
      node: target,
      // Arm a cleanup in case the node is unmounted mid-hover.
      cleanup: target.onUnmount(() => _exit(pointer, hover)),
    );

    if (target is HoverInput) target.enter(hover);
  }

  /// Drops [pointer]'s hover, emitting `onHoverExit`.
  void _exit(int pointer, HoverEvent event) {
    final hovered = _hovered.remove(pointer);
    if (hovered == null) return;
    hovered.cleanup();
    final node = hovered.node;
    if (node is HoverInput && node.isMounted) node.exit(event);
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

/// A pointer's current hover, and the subscription arming its exit on unmount.
final class _Hover {
  final InputNode node;
  final Cleanup cleanup;

  const _Hover({
    required this.node,
    required this.cleanup,
  });
}
