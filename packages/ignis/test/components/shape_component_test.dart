import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/canvas.dart';
import '../support/colors.dart';

void main() {
  test('draws its own shape', () {
    final shape = ShapeComponent(
      shape: .square(40),
      paint: Paint()..color = RED,
    );

    Scene(Entity(components: [shape]));
    final canvas = RecordingCanvas();
    shape.render(canvas);

    expect(canvas.rects, [const Rect.fromLTWH(0, 0, 40, 40)]);
  });
}
