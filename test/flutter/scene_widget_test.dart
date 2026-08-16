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

    expect(scene.node.passes, 1, reason: 'the first update');

    Ignis.cache.add('hero.png', 1);
    scene.update(0);
    expect(scene.node.passes, 2);

    Ignis.cache.evict('hero.png');
    scene.update(0);
    expect(scene.node.passes, 3);
  });

  testWidgets('destroys the scene once removed from the tree', (tester) async {
    addTearDown(Ignis.cache.clear);
    final scene = TestNode().mount();

    await tester.pumpWidget(
      SizedBox.square(
        dimension: 100,
        child: SceneWidget(scene),
      ),
    );

    await tester.pumpWidget(const SizedBox.square(dimension: 100));
    expect(scene.node.isMounted, isFalse);

    // Nothing is left listening, so the change reaches no one. A destroyed
    // scene resets its slots, so this can only be checked without an update.
    Ignis.cache.add('hero.png', 1);
    expect(scene.node.passes, 1, reason: 'the first update, and nothing since');
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
    scene.update(0);

    expect(scene.node.passes, 2);
  });

  testWidgets('carries hook state through a hot reload, but not its closures', (tester) async {
    final log = <String>[];
    var edited = false;
    Ref<Object>? state;

    final node = TestNode();

    node.action = () {
      state = node.fuseState(Object());
      log.add(edited ? 'new' : 'old');
    };

    final scene = node.mount()..update(0);
    final first = state;

    await tester.pumpWidget(
      SizedBox.square(
        dimension: 100,
        child: SceneWidget(scene),
      ),
    );

    expect(log, everyElement('old'));
    edited = true;

    // Never awaited directly: it locks events until the tree is pumped.
    unawaited(tester.binding.reassembleApplication());
    await tester.pump();
    log.clear();
    scene.update(0);

    expect(state, same(first), reason: 'fuseState survives the reload');
    expect(log, ['new'], reason: 'the tick body around it does not');
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
