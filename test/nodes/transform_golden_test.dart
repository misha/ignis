import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/colors.dart';
import '../support/expect.dart';

void main() {
  testWidgets(
    'offsets by position',
    (tester) => expectGolden(
      tester,
      'goldens/transform_position.png',
      ShapeNode(
        shape: .square(20),
        paint: Paint()..color = BLACK,
        anchor: .center,
        position: .all(25),
      ),
      debug: .spatial,
    ),
  );

  testWidgets(
    'scales non-uniformly',
    (tester) => expectGolden(
      tester,
      'goldens/transform_scale.png',
      ShapeNode(
        shape: .square(25),
        paint: Paint()..color = BLACK,
        anchor: .center,
        scale: .new(2, 1),
        position: .all(50),
      ),
      debug: .spatial,
    ),
  );

  testWidgets(
    'rotates by its angle',
    (tester) => expectGolden(
      tester,
      'goldens/transform_angle.png',
      ShapeNode(
        shape: .rectangle(.new(30, 10)),
        paint: Paint()..color = BLACK,
        anchor: .center,
        angle: math.pi / 4,
        position: .all(50),
      ),
      debug: .spatial,
    ),
  );

  testWidgets(
    'anchors from its top-left corner',
    (tester) => expectGolden(
      tester,
      'goldens/transform_anchor_top_left.png',
      SpatialNode(
        position: .all(50),
        children: [
          ShapeNode(
            shape: .square(30),
            paint: Paint()..color = BLACK,
            anchor: .topLeft,
          ),
        ],
      ),
      debug: .spatial,
    ),
  );

  testWidgets(
    'anchors from its bottom-right corner',
    (tester) => expectGolden(
      tester,
      'goldens/transform_anchor_bottom_right.png',
      SpatialNode(
        position: .all(50),
        children: [
          ShapeNode(
            shape: .square(30),
            paint: Paint()..color = BLACK,
            anchor: .bottomRight,
          ),
        ],
      ),
      debug: .spatial,
    ),
  );
}
