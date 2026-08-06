import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import 'support/colors.dart';
import 'support/expect.dart';

void main() {
  testWidgets(
    'offsets by position',
    (tester) => expectGolden(
      tester,
      'goldens/transform_position.png',
      ShapeNode(
        shape: .rectangle,
        paint: Paint()..color = BLACK,
        size: .all(20),
        anchor: .center(),
        position: Vector2(25, 25),
      ),
    ),
  );

  testWidgets(
    'scales non-uniformly',
    (tester) => expectGolden(
      tester,
      'goldens/transform_scale.png',
      ShapeNode(
        shape: .rectangle,
        paint: Paint()..color = BLACK,
        size: .all(25),
        anchor: .center(),
        scale: Vector2(2, 1),
        position: Vector2(50, 50),
      ),
    ),
  );

  testWidgets(
    'rotates by its angle',
    (tester) => expectGolden(
      tester,
      'goldens/transform_angle.png',
      ShapeNode(
        shape: .rectangle,
        paint: Paint()..color = BLACK,
        size: Vector2(30, 10),
        anchor: .center(),
        angle: math.pi / 4,
        position: Vector2(50, 50),
      ),
    ),
  );

  testWidgets(
    'anchors from its top-left corner',
    (tester) => expectGolden(
      tester,
      'goldens/transform_anchor_top_left.png',
      TransformNode(
        position: Vector2(50, 50),
        children: [
          ShapeNode(
            shape: .rectangle,
            paint: Paint()..color = BLACK,
            size: Vector2(30, 30),
            anchor: .topLeft(),
          ),
        ],
      ),
    ),
  );

  testWidgets(
    'anchors from its bottom-right corner',
    (tester) => expectGolden(
      tester,
      'goldens/transform_anchor_bottom_right.png',
      TransformNode(
        position: Vector2(50, 50),
        children: [
          ShapeNode(
            shape: .rectangle,
            paint: Paint()..color = BLACK,
            size: Vector2(30, 30),
            anchor: .bottomRight(),
          ),
        ],
      ),
    ),
  );
}
