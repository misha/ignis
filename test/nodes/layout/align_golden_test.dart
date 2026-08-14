import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../../support/colors.dart';
import '../../support/expect.dart';

void main() {
  testWidgets(
    'centers a child by default',
    (tester) => expectGolden(
      tester,
      'goldens/align_default.png',
      AlignNode(
        children: [
          ShapeNode(
            shape: .square(20),
            paint: Paint()..color = BLACK,
          ),
        ],
      ),
    ),
  );

  testWidgets(
    'aligns a child per a custom alignment',
    (tester) => expectGolden(
      tester,
      'goldens/align_bottom_right.png',
      AlignNode(
        alignment: .bottomRight,
        children: [
          ShapeNode(
            shape: .square(20),
            paint: Paint()..color = BLACK,
          ),
        ],
      ),
    ),
  );

  testWidgets(
    'aligns multiple children sharing the same alignment',
    (tester) => expectGolden(
      tester,
      'goldens/align_multiple_children.png',
      AlignNode(
        alignment: .bottomRight,
        children: [
          ShapeNode(
            shape: .square(40),
            paint: Paint()..color = BLACK,
          ),
          ShapeNode(
            shape: .square(20),
            paint: Paint()..color = RED,
          ),
        ],
      ),
    ),
  );
}
