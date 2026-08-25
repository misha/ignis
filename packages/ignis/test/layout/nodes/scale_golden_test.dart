import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../../support/colors.dart';
import '../../support/expect.dart';

void main() {
  testWidgets(
    'shrink-wraps to a scaled child\'s scaled extent',
    (tester) => expectGolden(
      tester,
      'goldens/scale_box_shrink_wrap.png',
      BoxNode(
        children: [
          ShapeNode(
            shape: .square(20),
            paint: Paint()..color = BLACK,
            scale: .all(2),
          ),
        ],
      ),
      debug: .layout,
    ),
  );

  testWidgets(
    'centers a scaled child on its scaled extent',
    (tester) => expectGolden(
      tester,
      'goldens/scale_box_align_center.png',
      BoxNode(
        alignment: .center,
        children: [
          ShapeNode(
            shape: .square(20),
            paint: Paint()..color = BLACK,
            scale: .all(2),
          ),
        ],
      ),
      debug: .layout,
    ),
  );

  testWidgets(
    'advances a row by a scaled child\'s scaled width',
    (tester) => expectGolden(
      tester,
      'goldens/scale_row_advance.png',
      RowNode(
        children: [
          ShapeNode(
            shape: .square(20),
            paint: Paint()..color = RED,
            scale: .all(2),
          ),
          ShapeNode(
            shape: .square(20),
            paint: Paint()..color = BLACK,
          ),
        ],
      ),
      debug: .layout,
    ),
  );
}
