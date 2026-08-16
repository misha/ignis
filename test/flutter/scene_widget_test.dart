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

    expect(scene.node.builds, 1, reason: 'the mount pass');

    Ignis.cache.add('hero.png', 1);
    expect(scene.node.builds, 2);

    Ignis.cache.evict('hero.png');
    expect(scene.node.builds, 3);
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
    expect(scene.node.builds, 1, reason: 'the mount pass, and nothing since');
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

    expect(scene.node.builds, 2);
  });

  testWidgets('a hot reload replaces the body but keeps what hooks own', (
    tester,
  ) async {
    final log = <String>[];
    var edited = false;
    final node = TestNode();
    late Node child;

    node.buildAction = () {
      child = node.fuseChild(Node.new);
      node.fuseUpdate((_) => log.add(edited ? 'new' : 'old'));
    };

    final scene = node.mount();
    final first = child;

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

    expect(child, same(first), reason: 'fuseChild survives the reload');
    expect(log, ['new'], reason: 'the tick closure around it does not');
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
