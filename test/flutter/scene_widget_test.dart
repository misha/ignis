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

    expect(scene.node.mounts, 1);
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

    expect(scene.node.isMounted, isTrue);
    expect(scene.node.unmounts, 0);
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

    expect(scene.node.isMounted, isTrue);
    expect(scene.node.unmounts, 0);
  });

  testWidgets('primes the scene exactly once, not on every layout', (tester) async {
    await tester.binding.setSurfaceSize(const Size(100, 80));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final scene = TestNode().mount();
    await tester.pumpWidget(SceneWidget(scene, paused: true));
    expect(scene.node.updates, 1);

    await tester.pumpWidget(SceneWidget(scene, paused: true));
    await tester.binding.setSurfaceSize(const Size(200, 80));
    await tester.pump();

    expect(scene.node.updates, 1);
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
    expect(scene.node.updates, greaterThanOrEqualTo(1));

    await tester.pumpWidget(harness(enabled: false));
    await tester.pump(const Duration(milliseconds: 16));
    final coveredUpdates = scene.node.updates;

    await tester.pump(const Duration(milliseconds: 16));
    expect(scene.node.updates, coveredUpdates);

    await tester.pumpWidget(harness(enabled: true));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));

    expect(scene.node.updates, greaterThan(coveredUpdates));
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

    expect(sceneA.node.isMounted, isFalse);
    expect(sceneB.node.isMounted, isTrue);
  });

  testWidgets('destroys the scene when disposed', (tester) async {
    final scene = TestNode().mount();

    await tester.pumpWidget(SceneWidget(scene));
    await tester.pumpWidget(const SizedBox());

    expect(scene.node.isMounted, isFalse);
    expect(scene.node.unmounts, 1);
  });

  testWidgets('resizes the node and performs an initial update', (tester) async {
    await tester.binding.setSurfaceSize(const Size(100, 80));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final scene = TestNode().mount();
    await tester.pumpWidget(SceneWidget(scene));

    expect(scene.size, Vector2(100, 80));
    expect(scene.node.mounts, 1);
    expect(scene.node.updates, 1);
    expect(scene.node.elapsed, 0);
  });

  testWidgets('reassembles the scene when the cache changes', (tester) async {
    addTearDown(Ignis.cache.clear);
    final scene = TestNode().mount();

    await tester.pumpWidget(
      SizedBox.square(
        dimension: 100,
        child: SceneWidget(scene),
      ),
    );

    expect(scene.node.reassembles, 0);

    Ignis.cache.add('hero.png', 1);
    expect(scene.node.reassembles, 1);

    Ignis.cache.evict('hero.png');
    expect(scene.node.reassembles, 2);
  });

  testWidgets('stops reassembling once removed from the tree', (tester) async {
    addTearDown(Ignis.cache.clear);
    final scene = TestNode().mount();

    await tester.pumpWidget(
      SizedBox.square(
        dimension: 100,
        child: SceneWidget(scene),
      ),
    );

    await tester.pumpWidget(const SizedBox.square(dimension: 100));

    Ignis.cache.add('hero.png', 1);
    expect(scene.node.reassembles, 0);
  });

  testWidgets('reassembles the scene on hot reload', (tester) async {
    final scene = TestNode().mount();

    await tester.pumpWidget(
      SizedBox.square(
        dimension: 100,
        child: SceneWidget(scene),
      ),
    );

    // Never awaited directly: it locks events until the tree is pumped.
    unawaited(tester.binding.reassembleApplication());
    await tester.pump();

    expect(scene.node.reassembles, 1);
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
