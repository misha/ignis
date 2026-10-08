import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/colors.dart';
import '../support/expect.dart';

void main() {
  testWidgets(
    'renders a red square',
    (tester) => expectGolden(
      tester,
      'goldens/shape_red_square.png',
      Entity(
        position: .all(50),
        components: [
          ShapeComponent(
            anchor: .center,
            shape: .square(50),
            paint: Paint()..color = RED,
          ),
        ],
      ),
      debug: .spatial,
    ),
  );

  testWidgets(
    'renders a blue circle',
    (tester) => expectGolden(
      tester,
      'goldens/shape_blue_circle.png',
      Entity(
        position: .all(50),
        components: [
          ShapeComponent(
            anchor: .center,
            shape: .circle(25),
            paint: Paint()..color = BLUE,
          ),
        ],
      ),
      debug: .spatial,
    ),
  );
}
