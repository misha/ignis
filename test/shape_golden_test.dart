import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import 'support/colors.dart';
import 'support/expect.dart';

void main() {
  testWidgets(
    'renders a red square',
    (tester) => expectGolden(
      tester,
      'goldens/shape_red_square.png',
      ShapeNode(
        shape: .square(50),
        paint: Paint()..color = RED,
        anchor: .center(),
        position: .all(50),
      ),
    ),
  );

  testWidgets(
    'renders a blue circle',
    (tester) => expectGolden(
      tester,
      'goldens/shape_blue_circle.png',
      ShapeNode(
        shape: .circle(25),
        paint: Paint()..color = BLUE,
        anchor: .center(),
        position: .all(50),
      ),
    ),
  );
}
