import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/canvas.dart';
import '../support/colors.dart';
import '../support/test_entity.dart';

void main() {
  test('takes no layer at all at opacity 1', () {
    final layer = Entity(
      children: [
        Entity(
          shape: .square(50),
          components: [ShapeComponent(shape: .square(50), paint: Paint()..color = RED)],
        ),
      ],
    );

    Scene(layer);
    final canvas = RecordingCanvas();
    layer.render(canvas);

    expect(canvas.saveLayers, 0);
  });

  test('takes one layer at mid opacity', () {
    final layer = Entity(
      opacity: 0.5,
      children: [
        Entity(
          shape: .square(50),
          components: [ShapeComponent(shape: .square(50), paint: Paint()..color = RED)],
        ),
      ],
    );

    Scene(layer);
    final canvas = RecordingCanvas();
    layer.render(canvas);

    expect(canvas.saveLayers, 1);
  });

  test('skips the subtree entirely at opacity 0', () {
    final child = TestEntity();
    final layer = Entity(opacity: 0, children: [child]);

    Scene(layer);
    layer.render(RecordingCanvas());

    expect(child.renders, 0);
  });

  test('never renders a disabled child into the layer', () {
    final child = TestEntity(enabled: false);
    final layer = Entity(opacity: 0.5, children: [child]);

    Scene(layer);
    layer.render(RecordingCanvas());

    expect(child.renders, 0);
  });

  test('clamps to the 0..1 range', () {
    final layer = Entity(opacity: 0.5);

    layer.opacity = 1.5;
    expect(layer.opacity, 1);

    layer.opacity = -0.2;
    expect(layer.opacity, 0);
  });
}
