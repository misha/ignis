import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../../support/colors.dart';
import '../../support/expect.dart';

void main() {
  testWidgets(
    'confines a nested aligned BoxNode to its fixed size',
    (tester) => expectGolden(
      tester,
      'goldens/box_fixed_size.png',
      BoxNode.square(
        size: 40,
        children: [
          BoxNode(
            alignment: .bottomRight,
            children: [
              ShapeNode(
                shape: .square(10),
                paint: Paint()..color = BLACK,
              ),
            ],
          ),
        ],
      ),
    ),
  );

  testWidgets(
    'fixes one axis and shrinks to the child on the other',
    (tester) => expectGolden(
      tester,
      'goldens/box_single_axis.png',
      RowNode(
        children: [
          BoxNode(
            width: 60,
            children: [
              ShapeNode(
                shape: .square(20),
                paint: Paint()..color = RED,
              ),
            ],
          ),
        ],
      ),
    ),
  );

  testWidgets(
    'stacks multiple children at the local origin',
    (tester) => expectGolden(
      tester,
      'goldens/box_multiple_children.png',
      BoxNode.square(
        size: 50,
        children: [
          ShapeNode(
            shape: .square(50),
            paint: Paint()..color = BLACK,
          ),
          ShapeNode(
            shape: .square(25),
            paint: Paint()..color = RED,
          ),
        ],
      ),
    ),
  );

  testWidgets(
    'insets a child by its padding within a fixed size',
    (tester) => expectGolden(
      tester,
      'goldens/box_padding.png',
      BoxNode.square(
        size: 50,
        padding: .all(10),
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
    'insets a single child with no fixed size',
    (tester) => expectGolden(
      tester,
      'goldens/padding_single_child.png',
      BoxNode(
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
      BoxNode(
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

  testWidgets(
    'centers a child',
    (tester) => expectGolden(
      tester,
      'goldens/align_default.png',
      BoxNode(
        alignment: .center,
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
      BoxNode(
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
      BoxNode(
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
