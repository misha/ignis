import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../../support/colors.dart';
import '../../support/expect.dart';

void main() {
  testWidgets(
    'insets a single child',
    (tester) => expectGolden(
      tester,
      'goldens/padding_single_child.png',
      PaddingNode(
        padding: .all(15),
        children: [
          ShapeNode(
            shape: .square(40),
            paint: Paint()..color = BLACK,
          ),
        ],
      ),
    ),
  );

  testWidgets(
    'insets every child by the same padding',
    (tester) => expectGolden(
      tester,
      'goldens/padding_multiple_children.png',
      PaddingNode(
        padding: .fromLTRB(10, 20, 0, 0),
        children: [
          ShapeNode(
            shape: .square(50),
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
