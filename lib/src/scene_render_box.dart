import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ignis/src/input_router.dart';
import 'package:ignis/src/node.dart';
import 'package:ignis/src/render_loop.dart';
import 'package:ignis/src/scene_widget.dart';

/// A [RenderObjectWidget] that renders the [SceneRenderBox].
///
/// This is the widget used by [SceneWidget] to actually render the scene.
@internal
class RenderSceneWidget extends LeafRenderObjectWidget {
  final Scene scene;
  final bool addRepaintBoundary;
  final bool paused;
  final bool debug;

  const RenderSceneWidget({
    required this.scene,
    required this.addRepaintBoundary,
    this.paused = false,
    this.debug = false,
    super.key,
  });

  @override
  RenderBox createRenderObject(BuildContext context) {
    return SceneRenderBox(
      scene,
      isRepaintBoundary: addRepaintBoundary,
      isPaused: paused,
      isDebug: debug,
    );
  }

  @override
  void updateRenderObject(BuildContext context, SceneRenderBox renderObject) {
    renderObject
      ..scene = scene
      ..isRepaintBoundary = addRepaintBoundary
      ..isPaused = paused
      ..isDebug = debug;
  }
}

@internal
class SceneRenderBox extends RenderBox {
  RenderLoop? renderLoop;

  Scene _scene;
  bool _isPaused;
  bool _isDebug;
  bool _isRepaintBoundary;
  late final _inputRouter = InputRouter(this);

  Scene get scene => _scene;

  SceneRenderBox(
    this._scene, {
    this._isPaused = false,
    this._isDebug = false,
    required this._isRepaintBoundary,
  });

  set scene(Scene value) {
    if (identical(_scene, value)) return;
    if (attached) _detachScene();
    _scene = value;
    if (attached) _attachScene();
  }

  set isPaused(bool value) {
    if (_isPaused == value) return;
    _isPaused = value;

    if (_isPaused) {
      renderLoop?.stop();
    } else {
      renderLoop?.start();
    }
  }

  set isDebug(bool value) {
    if (_isDebug == value) return;
    _isDebug = value;
    markNeedsPaint();
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
    _attachScene();
  }

  void _attachScene() {
    final renderLoop = this.renderLoop = RenderLoop(_renderLoopCallback);
    if (!_isPaused) renderLoop.start();
  }

  @override
  void detach() {
    super.detach();
    _detachScene();
  }

  void _detachScene() {
    renderLoop?.dispose();
    renderLoop = null;
  }

  @override
  void dispose() {
    scene.destroy();
    super.dispose();
  }

  void _renderLoopCallback(double dt) {
    // TODO: Probably one of these is extraneous.
    assert(attached);
    if (!attached) return;
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
    scene.render(canvas, debug: _isDebug);
    canvas.translate(-offset.dx, -offset.dy);
  }
}
