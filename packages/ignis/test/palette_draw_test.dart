import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import 'support/colors.dart';
import 'support/images.dart';

/// A 10x10 square at the origin, drawn with [color] as its default paint.
ShapeNode _square(Color color) {
  return ShapeNode(
    shape: .square(10),
    paint: Paint()..color = color,
  )..mount();
}

void main() {
  test('draws the default paint at the origin', () async {
    final node = _square(RED);
    final image = await renderImage(node, 10, 10);

    expect(await pixelAt(image, 5, 5), RED);
  });

  test('draws every enabled paint, in priority order', () async {
    final node = _square(RED);
    node.palette.add(.new('over', Paint()..color = BLUE, priority: 1));
    node.palette.add(.new('under', Paint()..color = GREEN, priority: -1));

    final image = await renderImage(node, 10, 10);

    expect(
      await pixelAt(image, 5, 5),
      BLUE,
      reason: 'the highest priority paint lands on top',
    );
  });

  test('skips disabled paints', () async {
    final node = _square(RED);

    node.palette.add(
      .new('glow', Paint()..color = BLUE, priority: 1, enabled: false),
    );

    final image = await renderImage(node, 10, 10);

    expect(await pixelAt(image, 5, 5), RED, reason: 'the glow never drew');
  });

  test("translates by each paint's individual offset", () async {
    final node = _square(RED);

    node.palette.add(
      .new('shadow', Paint()..color = GREEN, offset: .new(10, 0), priority: -1),
    );

    final image = await renderImage(node, 20, 10);

    expect(await pixelAt(image, 5, 5), RED, reason: 'the default paint');
    expect(await pixelAt(image, 15, 5), GREEN, reason: 'the shadow, offset');
  });

  test('reverses each offset, so they never accumulate', () async {
    final node = _square(RED);

    node.palette.add(
      .new('shadow', Paint()..color = GREEN, offset: .new(10, 0), priority: -1),
    );

    node.palette.add(
      .new('glow', Paint()..color = BLUE, offset: .new(10, 0), priority: 1),
    );

    final image = await renderImage(node, 30, 10);

    expect(
      await pixelAt(image, 15, 5),
      BLUE,
      reason: "glow sits at 10, not at 20 on top of shadow's translate",
    );

    expect(
      await pixelAt(image, 25, 5),
      TRANSPARENT,
      reason: 'nothing drew past 20',
    );
  });
}
