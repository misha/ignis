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
