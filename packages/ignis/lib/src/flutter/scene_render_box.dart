// SPDX-AI-Disclosure: ai-assisted

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ignis/src/core.dart';
import 'package:ignis/src/flutter/input_router.dart';
import 'package:ignis/src/flutter/render_loop.dart';
import 'package:ignis/src/flutter/scene_widget.dart';

/// A [RenderObjectWidget] that renders the [SceneRenderBox].
///
/// This is the widget used by [SceneWidget] to actually render the scene.
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
  Cleanup? _unwatch;
  late final _inputRouter = InputRouter(this);

  Scene get scene => _scene;

  SceneRenderBox(
    this._scene, {
    required this._isRepaintBoundary,
    this._muted = false,
  });

  set scene(Scene value) {
    if (identical(_scene, value)) return;
    _scene = value;
    if (attached) _watch();
    markNeedsPaint();
  }

  /// Tracks this scene's pause, which a hotkey may flip without the widget
  /// tree hearing about it.
  void _watch() {
    _unwatch?.call();
    _unwatch = _scene.onPause.watch(_apply);
    _apply();
  }

  /// Whether the surrounding tree has its tickers off, so this scene stops
  /// drawing without being paused.
  set muted(bool value) {
    if (_muted == value) return;
    _muted = value;
    _apply();
  }

  void _apply() {
    if (_scene.paused || _muted) {
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
    _watch();
  }

  // Detach pairs with attach and can recur, e.g. on reparenting, so it only
  // stops the loop. Destruction belongs to [SceneWidget] alone.
  @override
  void detach() {
    super.detach();
    _unwatch?.call();
    _unwatch = null;
    renderLoop?.dispose();
    renderLoop = null;
  }

  void _renderLoopCallback(double dt) {
    scene.update(dt);
    markNeedsPaint();
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) => _inputRouter.handle(event);

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    // TODO: What's faster, manually un-translating or save/restore?
    canvas.translate(offset.dx, offset.dy);
    scene.render(canvas);
    canvas.translate(-offset.dx, -offset.dy);
  }
}
