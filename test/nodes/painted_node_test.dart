import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

class _TestPaintedNode extends PaintedNode {
  final calls = <(Paint paint, double x, double y)>[];

  _TestPaintedNode({
    super.paint,
  });

  @override
  double get width => 0;

  @override
  double get height => 0;

  @override
  void renderPainted(Canvas canvas, Paint paint) {
    final transform = canvas.getTransform();
    calls.add((paint, transform[12], transform[13]));
  }
}

void main() {
  test('draws the default paint at the origin', () {
    final paint = Paint();
    final node = _TestPaintedNode(paint: paint);
    _render(node);
    expect(node.calls, [(paint, 0.0, 0.0)]);
  });

  test('draws every enabled paint, in priority order', () {
    final node = _TestPaintedNode();
    final b = node.palette.add(.new('b', Paint(), priority: 1));
    final c = node.palette.add(.new('c', Paint(), priority: -1));
    _render(node);

    expect(node.calls.map((call) => call.$1), [c.paint, node.paint, b.paint]);
  });

  test('skips disabled paints', () {
    final node = _TestPaintedNode();
    final glow = node.palette.add(.new('glow', Paint(), enabled: false));
    _render(node);

    expect(node.calls.map((call) => call.$1), [node.paint]);
    expect(node.calls.map((call) => call.$1), isNot(contains(glow.paint)));
  });

  test('translates by each paint\'s individual offset', () {
    final node = _TestPaintedNode();
    final shadow = node.palette.add(
      .new(
        'shadow',
        Paint(),
        offset: .all(5),
        priority: -1,
      ),
    );

    final glow = node.palette.add(
      .new(
        'glow',
        Paint(),
        offset: .new(10, 20),
        priority: 1,
      ),
    );

    _render(node);

    // If the shadow's translate weren't reversed, glow's would read (15, 25).
    expect(node.calls, [
      (shadow.paint, 5.0, 5.0),
      (node.paint, 0.0, 0.0),
      (glow.paint, 10.0, 20.0),
    ]);
  });
}

void _render(Node node) {
  final recorder = PictureRecorder();
  node.render(Canvas(recorder));
  recorder.endRecording();
}
