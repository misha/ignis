import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/canvas.dart';
import '../support/colors.dart';
import '../support/test_node.dart';

void main() {
  test('clips its subtree to its shape', () {
    final clip = ClipNode(
      shape: .square(50),
      children: [ShapeNode(shape: .square(100), paint: Paint()..color = RED)],
    );

    clip.mount();
    final canvas = RecordingCanvas();
    clip.render(canvas);

    expect(canvas.clips, [const Rect.fromLTWH(0, 0, 50, 50)]);
    expect(canvas.rects, [const Rect.fromLTWH(0, 0, 100, 100)]);
  });

  test('clips to the parent\'s shape when given none', () {
    final clip = ClipNode(children: [TestNode()]);
    ShapeNode(shape: .square(40), children: [clip]).mount();
    final canvas = RecordingCanvas();
    clip.render(canvas);

    expect(canvas.clips, [const Rect.fromLTWH(0, 0, 40, 40)]);
  });
}
