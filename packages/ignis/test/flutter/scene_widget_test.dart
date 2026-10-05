import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';
import 'package:ignis/src/flutter/scene_render_box.dart';

import '../support/test_node.dart';

void main() {
  testWidgets('passes the same scene through on rebuild', (tester) async {
    final scene = TestNode().mount();

    await tester.pumpWidget(
      SizedBox.square(
        dimension: 100,
        child: SceneWidget(scene),
      ),
    );

    await tester.pumpWidget(
      SizedBox.square(
        dimension: 100,
        child: SceneWidget(scene),
      ),
    );

    expect(scene.root.mounts, 1);
    expect(tester.widget<RenderSceneWidget>(find.byType(RenderSceneWidget)).scene, same(scene));
  });

  testWidgets('swaps to a new scene when given a different one', (tester) async {
    final sceneA = Node().mount();
    final sceneB = Node().mount();

    await tester.pumpWidget(
      SizedBox.square(
        dimension: 100,
        child: SceneWidget(sceneA),
      ),
    );

    expect(tester.widget<RenderSceneWidget>(find.byType(RenderSceneWidget)).scene, same(sceneA));

    await tester.pumpWidget(
      SizedBox.square(
        dimension: 100,
        child: SceneWidget(sceneB),
      ),
    );

    expect(tester.widget<RenderSceneWidget>(find.byType(RenderSceneWidget)).scene, same(sceneB));
  });

  testWidgets('survives being reparented', (tester) async {
    final key = GlobalKey();
    final scene = TestNode().mount();

    await tester.pumpWidget(
      SizedBox.square(
        dimension: 100,
        child: SceneWidget(scene, key: key),
      ),
    );

    await tester.pumpWidget(
      Center(
        child: SizedBox.square(
          dimension: 100,
          child: SceneWidget(scene, key: key),
        ),
      ),
    );

    expect(scene.root.isMounted, isTrue);
    expect(scene.root.unmounts, 0);
  });

  testWidgets('survives a transiently empty layout', (tester) async {
    final scene = TestNode().mount();

    await tester.pumpWidget(
      SizedBox.square(
        dimension: 100,
        child: SceneWidget(scene),
      ),
    );

    await tester.pumpWidget(
      SizedBox.square(
        dimension: 0,
        child: SceneWidget(scene),
      ),
    );

    await tester.pumpWidget(
      SizedBox.square(
        dimension: 100,
        child: SceneWidget(scene),
      ),
    );

    expect(scene.root.isMounted, isTrue);
    expect(scene.root.unmounts, 0);
  });

  testWidgets('primes the scene exactly once, not on every layout', (tester) async {
    await tester.binding.setSurfaceSize(const Size(100, 80));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final scene = TestNode().mount()..pause();
    await tester.pumpWidget(SceneWidget(scene));
    expect(scene.root.updates, 1);

    await tester.pumpWidget(SceneWidget(scene));
    await tester.binding.setSurfaceSize(const Size(200, 80));
    await tester.pump();

    expect(scene.root.updates, 1);
  });

  testWidgets('auto-pauses while its tickers are disabled', (tester) async {
    final scene = TestNode().mount();

    Widget harness({required bool enabled}) {
      return TickerMode(
        enabled: enabled,
        child: SizedBox.square(
          dimension: 100,
          child: SceneWidget(scene),
        ),
      );
    }

    await tester.pumpWidget(harness(enabled: true));
    await tester.pump(const Duration(milliseconds: 16));
    expect(scene.root.updates, greaterThanOrEqualTo(1));

    await tester.pumpWidget(harness(enabled: false));
    await tester.pump(const Duration(milliseconds: 16));
    final coveredUpdates = scene.root.updates;

    await tester.pump(const Duration(milliseconds: 16));
    expect(scene.root.updates, coveredUpdates);

    await tester.pumpWidget(harness(enabled: true));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));

    expect(scene.root.updates, greaterThan(coveredUpdates));
  });

  testWidgets('destroys the scene when swapped for a different one', (tester) async {
    final sceneA = Node().mount();
    final sceneB = Node().mount();

    await tester.pumpWidget(
      SizedBox.square(
        dimension: 100,
        child: SceneWidget(sceneA),
      ),
    );

    await tester.pumpWidget(
      SizedBox.square(
        dimension: 100,
        child: SceneWidget(sceneB),
      ),
    );

    expect(sceneA.root.isMounted, isFalse);
    expect(sceneB.root.isMounted, isTrue);
  });

  testWidgets('destroys the scene when disposed', (tester) async {
    final scene = TestNode().mount();

    await tester.pumpWidget(SceneWidget(scene));
    await tester.pumpWidget(const SizedBox());

    expect(scene.root.isMounted, isFalse);
    expect(scene.root.unmounts, 1);
  });

  testWidgets('resizes the node and performs an initial update', (tester) async {
    await tester.binding.setSurfaceSize(const Size(100, 80));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final scene = TestNode().mount();
    await tester.pumpWidget(SceneWidget(scene));

    expect(scene.size, Vector2(100, 80));
    expect(scene.root.mounts, 1);
    expect(scene.root.updates, 1);
    expect(scene.root.elapsed, 0);
  });

  testWidgets('reassembles the scene on hot reload', (tester) async {
    final scene = LiveTestNode().mount();

    await tester.pumpWidget(
      SizedBox.square(
        dimension: 100,
        child: SceneWidget(scene),
      ),
    );

    // Never awaited directly: it locks events until the tree is pumped.
    unawaited(tester.binding.reassembleApplication());
    await tester.pump();

    expect(scene.root.builds, 2);
  });

  testWidgets('paints against the given background color', (tester) async {
    const COLOR = Color(0xFFAABBCC);

    await tester.pumpWidget(
      SizedBox.square(
        dimension: 100,
        child: SceneWidget(
          Node().mount(),
          color: COLOR,
        ),
      ),
    );

    final box = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    expect((box.decoration as BoxDecoration).color, COLOR);
  });
}
