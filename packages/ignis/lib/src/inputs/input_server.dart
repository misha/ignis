// SPDX-AI-Disclosure: ai-assisted

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:ignis/src/scene.dart';
import 'package:ignis/src/extensions.dart';
import 'package:ignis/src/flutter/scene_render_box.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/inputs/nodes/input_node.dart';

/// Resolves raw pointer events against a [Scene]'s tree and hands off to
/// whichever [InputNode]s claim them, per [InputNode.behavior].
@internal
class InputServer {
  final SceneRenderBox box;
  Scene get scene => box.scene;

  InputServer(this.box);

  bool dispatch(PointerEvent event) {
    switch (event) {
      case PointerDownEvent():
        return _handleDown(event);

      default:
        return false;
    }
  }

  bool _handleDown(PointerDownEvent event) {
    final point = event.localPosition.toVector2();
    return _offer(point, (node) => node.register(event, box.globalToLocal)) != null;
  }

  /// Walks [point]'s hit-test chain, offering each [InputNode] to [respond]
  /// until one is claimed by an opaque node.
  InputNode? _offer(Vector2 point, InputResult Function(InputNode) respond) {
    InputNode? result;

    for (final node in scene.root.hitTest(point).whereType<InputNode>()) {
      final response = respond(node);
      if (response == .ignored) continue;
      result ??= node;
      if (node.behavior == .opaque) break;
    }

    return result;
  }
}
