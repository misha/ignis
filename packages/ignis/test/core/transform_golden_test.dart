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
        position: .all(25),
        components: [
          ShapeComponent(
            shape: .square(20),
            anchor: .center,
            paint: Paint()..color = BLACK,
          ),
        ],
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
        position: .all(50),
        scale: .new(2, 1),
        components: [
          ShapeComponent(
            shape: .square(25),
            anchor: .center,
            paint: Paint()..color = BLACK,
          ),
        ],
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
        position: .all(50),
        angle: math.pi / 4,
        components: [
          ShapeComponent(
            anchor: .center,
            shape: .rectangle(.new(30, 10)),
            paint: Paint()..color = BLACK,
          ),
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
            components: [
              ShapeComponent(
                shape: .square(30),
                anchor: .topLeft,
                paint: Paint()..color = BLACK,
              ),
            ],
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
            components: [
              ShapeComponent(
                anchor: .bottomRight,
                shape: .square(30),
                paint: Paint()..color = BLACK,
              ),
            ],
          ),
        ],
      ),
      debug: .spatial,
    ),
  );
}
