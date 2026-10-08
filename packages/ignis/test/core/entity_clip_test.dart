import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/canvas.dart';
import '../support/colors.dart';

void main() {
  test('clips its subtree to its shape', () {
    final clip = Entity(
      shape: .square(50),
      clip: true,
      children: [
        Entity(
          shape: .square(100),
          components: [ShapeComponent(shape: .square(100), paint: Paint()..color = RED)],
        ),
      ],
    );

    Scene(clip);
    final canvas = RecordingCanvas();
    clip.render(canvas);

    expect(canvas.clips, [const Rect.fromLTWH(0, 0, 50, 50)]);
    expect(canvas.rects, [const Rect.fromLTWH(0, 0, 100, 100)]);
  });
}
