import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../../support/colors.dart';
import '../../support/expect.dart';

void main() {
  ShapeNode square(Color color, [double side = 15]) {
    return ShapeNode(
      shape: .square(side),
      paint: Paint()..color = color,
    );
  }

  group('RowNode', () {
    testWidgets(
      'lays out along the x axis',
      (tester) => expectGolden(
        tester,
        'goldens/flex_row.png',
        RowNode(
          children: [
            square(RED),
            square(GREEN),
            square(BLUE),
          ],
        ),
        debug: .layout,
      ),
    );

    testWidgets(
      'packs children at the trailing edge with end',
      (tester) => expectGolden(
        tester,
        'goldens/flex_row_end.png',
        RowNode(
          mainAxisAlignment: .end,
          children: [
            square(RED),
            square(GREEN),
            square(BLUE),
          ],
        ),
        debug: .layout,
      ),
    );

    testWidgets(
      'packs children around the middle with center',
      (tester) => expectGolden(
        tester,
        'goldens/flex_row_center.png',
        RowNode(
          mainAxisAlignment: .center,
          children: [
            square(RED),
            square(GREEN),
            square(BLUE),
          ],
        ),
        debug: .layout,
      ),
    );

    testWidgets(
      'spaces children with spaceBetween',
      (tester) => expectGolden(
        tester,
        'goldens/flex_row_space_between.png',
        RowNode(
          mainAxisAlignment: .spaceBetween,
          crossAxisAlignment: .center,
          children: [
            square(RED),
            square(GREEN),
            square(BLUE),
          ],
        ),
        debug: .layout,
      ),
    );

    testWidgets(
      'spaces children with half-gaps at the edges with spaceAround',
      (tester) => expectGolden(
        tester,
        'goldens/flex_row_space_around.png',
        RowNode(
          mainAxisAlignment: .spaceAround,
          children: [
            square(RED),
            square(GREEN),
            square(BLUE),
          ],
        ),
        debug: .layout,
      ),
    );

    testWidgets(
      'spaces children into equal gaps, edges included, with spaceEvenly',
      (tester) => expectGolden(
        tester,
        'goldens/flex_row_space_evenly.png',
        RowNode(
          mainAxisAlignment: .spaceEvenly,
          children: [
            square(RED),
            square(GREEN),
            square(BLUE),
          ],
        ),
        debug: .layout,
      ),
    );

    testWidgets(
      'positions short leaves at the cross-axis end of a tall sibling',
      (tester) => expectGolden(
        tester,
        'goldens/flex_row_cross_end.png',
        RowNode(
          crossAxisAlignment: .end,
          children: [
            ShapeNode(
              shape: Rectangle(.new(10, 60)),
              paint: Paint()..color = CYAN,
            ),
            square(RED),
            square(GREEN),
          ],
        ),
        debug: .layout,
      ),
    );

    testWidgets(
      'shrinks the main axis to fit consumed space with mainAxisSize.min',
      (tester) => expectGolden(
        tester,
        'goldens/flex_row_min.png',
        RowNode(
          mainAxisSize: .min,
          children: [
            square(RED),
            square(GREEN),
          ],
        ),
        debug: .layout,
      ),
    );

    testWidgets(
      'inserts extra room between adjacent children with spacing',
      (tester) => expectGolden(
        tester,
        'goldens/flex_row_spacing.png',
        RowNode(
          spacing: 10,
          children: [
            square(RED),
            square(GREEN),
            square(BLUE),
          ],
        ),
        debug: .layout,
      ),
    );

    testWidgets(
      'splits leftover space proportionally by flex weight',
      (tester) => expectGolden(
        tester,
        'goldens/flex_row_weighted.png',
        RowNode(
          children: [
            BoxNode(
              flex: .expanded(),
              children: [square(RED, 10)],
            ),
            BoxNode(
              flex: .expanded(3),
              children: [square(BLUE, 10)],
            ),
          ],
        ),
        debug: .layout,
      ),
    );

    testWidgets(
      'an empty expanded child acts as a flexible spacer between fixed children',
      (tester) => expectGolden(
        tester,
        'goldens/flex_row_spacer.png',
        RowNode(
          children: [
            square(RED),
            BoxNode(flex: .expanded()),
            square(BLUE),
          ],
        ),
        debug: .layout,
      ),
    );

    testWidgets(
      'mixes a fixed leaf, an expanded child, and a flexible child',
      (tester) => expectGolden(
        tester,
        'goldens/flex_row_expanded.png',
        RowNode(
          crossAxisAlignment: .start,
          children: [
            square(RED, 10),
            BoxNode(
              flex: .expanded(),
              children: [square(GREEN, 10)],
            ),
            BoxNode(
              flex: .flexible(),
              children: [square(BLUE, 10)],
            ),
          ],
        ),
        debug: .layout,
      ),
    );
  });

  group('ColumnNode', () {
    testWidgets(
      'lays out along the y axis',
      (tester) => expectGolden(
        tester,
        'goldens/flex_column.png',
        ColumnNode(
          children: [
            square(RED),
            square(GREEN),
            square(BLUE),
          ],
        ),
        debug: .layout,
      ),
    );

    testWidgets(
      'stretches an expanded child across the cross axis',
      (tester) => expectGolden(
        tester,
        'goldens/flex_column_stretch.png',
        ColumnNode(
          crossAxisAlignment: .stretch,
          children: [
            BoxNode(
              flex: .expanded(),
              children: [square(GREEN, 20)],
            ),
          ],
        ),
        debug: .layout,
      ),
    );
  });
}
