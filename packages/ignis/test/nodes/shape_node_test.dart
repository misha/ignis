import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/canvas.dart';
import '../support/colors.dart';

void main() {
  test('draws its own shape', () {
    final node = ShapeNode(shape: .square(40), paint: Paint()..color = RED);
    node.mount();
    final canvas = RecordingCanvas();
    node.render(canvas);

    expect(canvas.rects, [const Rect.fromLTWH(0, 0, 40, 40)]);
  });

  test('draws the parent\'s shape when given none', () {
    final fill = ShapeNode(paint: Paint()..color = RED);
    ShapeNode(shape: .square(40), children: [fill]).mount();
    final canvas = RecordingCanvas();
    fill.render(canvas);

    expect(canvas.rects, [const Rect.fromLTWH(0, 0, 40, 40)]);
  });

  test('a null shape goes back to the parent\'s', () {
    final fill = ShapeNode(shape: .square(10), paint: Paint()..color = RED);
    ShapeNode(shape: .square(40), children: [fill]).mount();

    fill.shape = .none;
    expect(fill.size.x, 40);
  });

  test('fills the nearest spatial ancestor, not an outer one', () {
    final fill = ShapeNode(paint: Paint()..color = RED);
    final inner = ShapeNode(shape: .square(10), children: [fill]);
    ShapeNode(shape: .square(80), children: [inner]).mount();

    expect(fill.size, Vector2.all(10));
  });

  test('fills through a node that is not spatial', () {
    final fill = ShapeNode(paint: Paint()..color = RED);
    final group = Node(children: [fill]);
    ShapeNode(shape: .circle(15), children: [group]).mount();

    expect(fill.shape, isA<Circle>());
  });
}
