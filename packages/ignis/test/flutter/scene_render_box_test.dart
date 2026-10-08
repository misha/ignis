import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';
import 'package:ignis/src/flutter/scene_render_box.dart';

import '../support/test_entity.dart';

void main() {
  Scene<TestEntity> makeScene() {
    final scene = Scene(TestEntity());
    scene.resize(100, 80);
    return scene;
  }

  test('is opaque to hit testing', () {
    final scene = makeScene();
    final box = SceneRenderBox(scene, isRepaintBoundary: true);
    expect(box.hitTestSelf(.zero), isTrue);
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
    expect(scene.root.updates, 2);
    expect(scene.root.elapsed, closeTo(0.016 * 2, 0.0001));
    expect(scene.root.renders, greaterThanOrEqualTo(2)); // Sometimes 3.
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
    expect(scene.root.updates, 1);

    scene.paused = true;
    await tester.pump(const Duration(milliseconds: 16));
    final updatesAfterPause = scene.root.updates;

    await tester.pump(const Duration(milliseconds: 16));
    expect(scene.root.updates, updatesAfterPause); // No longer driven while paused.

    scene.paused = false;
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    expect(scene.root.updates, greaterThan(updatesAfterPause));
  });

  testWidgets('starting paused drives no updates', (tester) async {
    final scene = makeScene()..paused = true;

    await tester.pumpWidget(
      RenderSceneWidget(
        scene: scene,
        addRepaintBoundary: true,
      ),
    );

    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    expect(scene.root.updates, 0);
  });

  testWidgets('stops driving the scene when removed, but never destroys it', (tester) async {
    final scene = makeScene();

    await tester.pumpWidget(
      RenderSceneWidget(
        scene: scene,
        addRepaintBoundary: true,
      ),
    );

    await tester.pump(const Duration(milliseconds: 16));
    expect(scene.root.isMounted, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    final updates = scene.root.updates;
    await tester.pump(const Duration(milliseconds: 16));

    expect(scene.root.isMounted, isTrue, reason: 'destruction belongs to SceneWidget');
    expect(scene.root.updates, updates);
  });

  testWidgets('detaches the old scene and attaches the new one on swap', (tester) async {
    final sceneA = makeScene();
    final sceneB = makeScene();

    await tester.pumpWidget(RenderSceneWidget(scene: sceneA, addRepaintBoundary: true));
    await tester.pump(const Duration(milliseconds: 16));
    expect(sceneA.root.updates, 1);

    await tester.pumpWidget(RenderSceneWidget(scene: sceneB, addRepaintBoundary: true));
    await tester.pump(const Duration(milliseconds: 16));
    final sceneAUpdatesAfterSwap = sceneA.root.updates;

    await tester.pump(const Duration(milliseconds: 16));
    expect(
      sceneA.root.updates,
      sceneAUpdatesAfterSwap,
    ); // No longer driven once detached.
    expect(sceneB.root.updates, greaterThanOrEqualTo(1));
  });
}
