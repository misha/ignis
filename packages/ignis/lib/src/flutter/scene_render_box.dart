// SPDX-AI-Disclosure: ai-assisted

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ignis/src/scene.dart';
import 'package:ignis/src/flutter/render_loop.dart';
import 'package:ignis/src/flutter/scene_widget.dart';
import 'package:ignis/src/extensions.dart';
import 'package:ignis/src/inputs/input_server.dart';
import 'package:ignis/src/inputs/nodes/hover_input.dart';

/// Hosts a [SceneRenderBox] for [SceneWidget].
@internal
class RenderSceneWidget extends LeafRenderObjectWidget {
  final Scene scene;
  final bool addRepaintBoundary;
  final bool muted;

  const RenderSceneWidget({
    required this.scene,
    required this.addRepaintBoundary,
    this.muted = false,
    super.key,
  });

  @override
  RenderBox createRenderObject(BuildContext context) {
    return SceneRenderBox(
      scene,
      isRepaintBoundary: addRepaintBoundary,
      muted: muted,
    );
  }

  @override
  void updateRenderObject(BuildContext context, SceneRenderBox renderObject) {
    renderObject
      ..scene = scene
      ..muted = muted
      ..isRepaintBoundary = addRepaintBoundary;
  }
}

@internal
class SceneRenderBox extends RenderBox {
  RenderLoop? renderLoop;

  Scene _scene;
  bool _isRepaintBoundary;
  bool _muted;
  late final _input = InputServer(this);

  Scene get scene => _scene;

  SceneRenderBox(
    this._scene, {
    required this._isRepaintBoundary,
    this._muted = false,
  });

  set scene(Scene value) {
    if (identical(_scene, value)) return;
    _scene = value;
    markNeedsPaint();
  }

  set muted(bool value) {
    if (_muted == value) return;
    _muted = value;
    _apply();
  }

  void _apply() {
    if (_muted) {
      renderLoop?.stop();
    } else {
      renderLoop?.start();
    }
  }

  set isRepaintBoundary(bool value) {
    if (_isRepaintBoundary == value) return;
    _isRepaintBoundary = value;
    markNeedsCompositingBitsUpdate();
  }

  @override
  bool get isRepaintBoundary => _isRepaintBoundary;

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    renderLoop = RenderLoop(_renderLoopCallback);
    _apply();
  }

  // Detach can recur, e.g. on reparenting, so it only stops the loop.
  // [SceneWidget] destroys the scene.
  @override
  void detach() {
    super.detach();
    renderLoop?.dispose();
    renderLoop = null;
  }

  void _renderLoopCallback(double dt) {
    if (scene.paused) return;
    scene.update(dt);
    markNeedsPaint();
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  bool hitTestChildren(
    BoxHitTestResult result, {
    required Offset position,
  }) {
    final nodes = scene.root
        .hitTest(position.toVector2()) //
        .whereType<HoverInput>();

    for (final node in nodes) {
      result.add(HitTestEntry(node));
      if (node.behavior == .opaque) break;
    }

    return false;
  }

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) => _input.dispatch(event);

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;

    if (offset.dx != 0 || offset.dy != 0) {
      canvas.translate(offset.dx, offset.dy);
      scene.render(canvas);
      canvas.translate(-offset.dx, -offset.dy);
    } else {
      scene.render(canvas);
    }
  }
}
