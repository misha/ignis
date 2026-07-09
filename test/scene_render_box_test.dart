import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';
import 'package:ignis/src/scene_render_box.dart';

import 'support/test_node.dart';

void main() {
  Scene<TestNode> makeScene() {
    final scene = TestNode().mount();
    scene.resize(100, 80);
    return scene;
  }

  test('is opaque to hit testing', () {
    final scene = makeScene();
    final box = SceneRenderBox(scene, isRepaintBoundary: true);
    expect(box.hitTestSelf(.zero), isTrue);
  });

  testWidgets('renders the node translated by half the scene size', (tester) async {
    final node = _TransformRecordingNode();
    final scene = node.mount();
    scene.resize(100, 80);

    await tester.pumpWidget(RenderSceneWidget(scene: scene, addRepaintBoundary: true));
    await tester.pump(const Duration(milliseconds: 16));

    expect(node.translation, const Offset(50, 40));
  });

  testWidgets('drives scene updates and paints every frame', (tester) async {
    final scene = makeScene();

    await tester.pumpWidget(
      RenderSceneWidget(
        scene: scene,
        addRepaintBoundary: true,
      ),
    );

    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    expect(scene.node.updates, 2);
    expect(scene.node.elapsed, closeTo(0.016 * 2, 0.0001));
    expect(scene.node.renders, greaterThanOrEqualTo(2)); // Sometimes 3.
  });

  testWidgets('stops driving updates while paused, and resumes afterwards', (tester) async {
    final scene = makeScene();

    await tester.pumpWidget(
      RenderSceneWidget(
        scene: scene,
        addRepaintBoundary: true,
      ),
    );

    await tester.pump(const Duration(milliseconds: 16));
    expect(scene.node.updates, 1);

    await tester.pumpWidget(
      RenderSceneWidget(
        scene: scene,
        paused: true,
        addRepaintBoundary: true,
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));
    final updatesAfterPause = scene.node.updates;

    await tester.pump(const Duration(milliseconds: 16));
    expect(scene.node.updates, updatesAfterPause); // No longer driven while paused.

    await tester.pumpWidget(
      RenderSceneWidget(
        scene: scene,
        addRepaintBoundary: true,
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    expect(scene.node.updates, greaterThan(updatesAfterPause));
  });

  testWidgets('starting paused does not start its render loop', (tester) async {
    final scene = makeScene();

    await tester.pumpWidget(
      RenderSceneWidget(
        scene: scene,
        paused: true,
        addRepaintBoundary: true,
      ),
    );

    await tester.pump(const Duration(milliseconds: 16));
    final box = tester.renderObject<SceneRenderBox>(find.byType(RenderSceneWidget));
    expect(box.renderLoop?.isRunning, isFalse);
  });

  testWidgets('unmounts the scene when permanently removed from the tree', (tester) async {
    final scene = makeScene();

    await tester.pumpWidget(
      RenderSceneWidget(
        scene: scene,
        addRepaintBoundary: true,
      ),
    );

    await tester.pump(const Duration(milliseconds: 16));
    expect(scene.node.isMounted, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(scene.node.isMounted, isFalse);
  });

  testWidgets('detaches the old scene and attaches the new one on swap', (tester) async {
    final sceneA = makeScene();
    final sceneB = makeScene();

    await tester.pumpWidget(RenderSceneWidget(scene: sceneA, addRepaintBoundary: true));
    await tester.pump(const Duration(milliseconds: 16));
    expect(sceneA.node.updates, 1);

    await tester.pumpWidget(RenderSceneWidget(scene: sceneB, addRepaintBoundary: true));
    await tester.pump(const Duration(milliseconds: 16));
    final sceneAUpdatesAfterSwap = sceneA.node.updates;

    await tester.pump(const Duration(milliseconds: 16));
    expect(sceneA.node.updates, sceneAUpdatesAfterSwap); // No longer driven once detached.
    expect(sceneB.node.updates, greaterThanOrEqualTo(1));
  });
}

class _TransformRecordingNode extends Node {
  late Offset translation;

  @override
  void render(Canvas canvas) {
    final transform = canvas.getTransform();
    translation = Offset(transform[12], transform[13]);
    super.render(canvas);
  }
}
