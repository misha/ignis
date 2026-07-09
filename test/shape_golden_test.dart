import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import 'support/colors.dart';
import 'support/expect.dart';

void main() {
  testWidgets(
    'renders a red square centered on white',
    (tester) => expectGolden(
      tester,
      'goldens/shape_red_square.png',
      ShapeNode(
        shape: .rectangle,
        paint: Paint()..color = RED,
        size: Vector2(50, 50),
        anchor: .center(),
      ),
    ),
  );

  testWidgets(
    'renders a blue circle centered on white',
    (tester) => expectGolden(
      tester,
      'goldens/shape_blue_circle.png',
      ShapeNode(
        shape: .circle,
        paint: Paint()..color = BLUE,
        size: Vector2(50, 50),
        anchor: .center(),
      ),
    ),
  );
}
