import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import 'support/colors.dart';
import 'support/expect.dart';

void main() {
  testWidgets('draws every enabled paint, in priority order', (tester) async {
    final node = ShapeNode(
      shape: .square(40),
      position: .all(20),
      paint: Paint()..color = RED,
    );

    node.palette
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

    await expectGolden(tester, 'goldens/palette_priority.png', node);
  });

  testWidgets("translates by each paint's own offset, never accumulating them", (tester) async {
    final node = ShapeNode(
      shape: .square(30),
      position: .all(10),
      paint: Paint()..color = RED,
    );

    node.palette
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

    await expectGolden(tester, 'goldens/palette_offsets.png', node);
  });
}
