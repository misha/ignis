import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../../support/colors.dart';
import '../../support/expect.dart';

void main() {
  group('RowNode', () {
    testWidgets(
      'spaces children with spaceBetween',
      (tester) => expectGolden(
        tester,
        'goldens/flex_row_space_between.png',
        RowNode(
          mainAxisAlignment: .spaceBetween,
          crossAxisAlignment: .center,
          children: [
            ShapeNode(
              shape: .square(15),
              paint: Paint()..color = RED,
            ),
            ShapeNode(
              shape: .square(15),
              paint: Paint()..color = GREEN,
            ),
            ShapeNode(
              shape: .square(15),
              paint: Paint()..color = BLUE,
            ),
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
            ShapeNode(
              shape: .square(10),
              paint: Paint()..color = RED,
            ),
            BoxNode(
              flex: .expanded(),
              children: [
                ShapeNode(
                  shape: .square(10),
                  paint: Paint()..color = GREEN,
                ),
              ],
            ),
            BoxNode(
              flex: .flexible(),
              children: [
                ShapeNode(
                  shape: .square(10),
                  paint: Paint()..color = BLUE,
                ),
              ],
            ),
          ],
        ),
        debug: .layout,
      ),
    );
  });

  group('ColumnNode', () {
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
              children: [
                ShapeNode(
                  shape: .square(20),
                  paint: Paint()..color = GREEN,
                ),
              ],
            ),
          ],
        ),
        debug: .layout,
      ),
    );
  });
}
