import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/canvas.dart';
import '../support/colors.dart';
import '../support/test_node.dart';

void main() {
  test('takes no layer at all at opacity 1', () {
    final layer = OpacityNode(
      children: [
        ShapeNode(
          shape: .square(50),
          paint: Paint()..color = RED,
        ),
      ],
    );

    layer.mount();
    final canvas = RecordingCanvas();
    layer.render(canvas);

    expect(canvas.saveLayers, 0);
  });

  test('takes one layer at mid opacity', () {
    final layer = OpacityNode(
      opacity: 0.5,
      children: [
        ShapeNode(
          shape: .square(50),
          paint: Paint()..color = RED,
        ),
      ],
    );

    layer.mount();
    final canvas = RecordingCanvas();
    layer.render(canvas);

    expect(canvas.saveLayers, 1);
  });

  test('skips the subtree entirely at opacity 0', () {
    final child = TestNode();
    final layer = OpacityNode(opacity: 0, children: [child]);

    layer.mount();
    layer.render(RecordingCanvas());

    expect(child.renders, 0);
  });

  test('never renders a disabled child into the layer', () {
    final child = TestNode(enabled: false);
    final layer = OpacityNode(opacity: 0.5, children: [child]);

    layer.mount();
    layer.render(RecordingCanvas());

    expect(child.renders, 0);
  });

  test('clamps to the 0..1 range', () {
    final layer = OpacityNode(opacity: 0.5);

    layer.opacity = 1.5;
    expect(layer.opacity, 1);

    layer.opacity = -0.2;
    expect(layer.opacity, 0);
  });
}
