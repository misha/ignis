// SPDX-AI-Disclosure: none

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:ignis/src/scene.dart';
import 'package:ignis/src/extensions.dart';
import 'package:ignis/src/flutter/scene_render_box.dart';
import 'package:ignis/src/inputs/nodes/input_node.dart';

/// Resolves raw pointer events against a [Scene]'s tree.
@internal
class InputServer {
  final SceneRenderBox box;
  Scene get scene => box.scene;

  InputServer(this.box);

  bool dispatch(PointerEvent event) {
    switch (event) {
      case PointerDownEvent():
        final point = event.localPosition.toVector2();
        final hits = scene.root.hitTest(point).whereType<InputNode>();
        var claimed = false;

        for (final hit in hits) {
          final result = hit.register(event, box.globalToLocal);

          if (result == .ignored) {
            continue;
          }

          claimed = true;

          if (hit.behavior == .opaque) {
            break;
          }
        }

        return claimed;

      default:
        return false;
    }
  }
}
