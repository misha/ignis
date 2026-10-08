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
      Entity(
        shape: .square(20),
        position: .all(25),
        anchor: .center,
        components: [ShapeComponent(shape: .square(20), paint: Paint()..color = BLACK)],
      ),
      debug: .spatial,
    ),
  );

  testWidgets(
    'scales non-uniformly',
    (tester) => expectGolden(
      tester,
      'goldens/transform_scale.png',
      Entity(
        shape: .square(25),
        position: .all(50),
        scale: .new(2, 1),
        anchor: .center,
        components: [ShapeComponent(shape: .square(25), paint: Paint()..color = BLACK)],
      ),
      debug: .spatial,
    ),
  );

  testWidgets(
    'rotates by its angle',
    (tester) => expectGolden(
      tester,
      'goldens/transform_angle.png',
      Entity(
        shape: .rectangle(.new(30, 10)),
        position: .all(50),
        angle: math.pi / 4,
        anchor: .center,
        components: [
          ShapeComponent(shape: .rectangle(.new(30, 10)), paint: Paint()..color = BLACK),
        ],
      ),
      debug: .spatial,
    ),
  );

  testWidgets(
    'anchors from its top-left corner',
    (tester) => expectGolden(
      tester,
      'goldens/transform_anchor_top_left.png',
      Entity(
        position: .all(50),
        children: [
          Entity(
            shape: .square(30),
            anchor: .topLeft,
            components: [ShapeComponent(shape: .square(30), paint: Paint()..color = BLACK)],
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
      Entity(
        position: .all(50),
        children: [
          Entity(
            shape: .square(30),
            anchor: .bottomRight,
            components: [ShapeComponent(shape: .square(30), paint: Paint()..color = BLACK)],
          ),
        ],
      ),
      debug: .spatial,
    ),
  );
}
