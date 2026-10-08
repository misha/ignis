import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import 'support/colors.dart';
import 'support/expect.dart';

void main() {
  testWidgets('draws every enabled paint, in priority order', (tester) async {
    final shape = ShapeComponent(
      shape: .square(40),
      paint: Paint()..color = RED,
    );

    final entity = Entity(
      shape: .square(40),
      position: .all(20),
      components: [shape],
    );

    shape.palette
      ..add(
        .new(
          'under',
          Paint()..color = GREEN,
          offset: .all(8),
          priority: -1,
        ),
      )
      ..add(
        .new(
          'over',
          Paint()..color = BLUE,
          offset: .all(16),
          priority: 1,
        ),
      )
      ..add(
        .new(
          'glow',
          Paint()..color = MAGENTA,
          offset: .all(30),
          priority: 2,
          enabled: false,
        ),
      );

    await expectGolden(tester, 'goldens/palette_priority.png', entity);
  });

  testWidgets("translates by each paint's own offset, never accumulating them", (tester) async {
    final shape = ShapeComponent(
      shape: .square(30),
      paint: Paint()..color = RED,
    );

    final entity = Entity(
      shape: .square(30),
      position: .all(10),
      components: [shape],
    );

    shape.palette
      ..add(
        .new(
          'shadow',
          Paint()..color = GREEN,
          offset: .new(20, 0),
          priority: -1,
        ),
      )
      ..add(
        .new(
          'glow',
          Paint()..color = BLUE,
          offset: .new(20, 0),
          priority: 1,
        ),
      );

    await expectGolden(tester, 'goldens/palette_offsets.png', entity);
  });
}
