import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import 'support/colors.dart';
import 'support/expect.dart';

void main() {
  testWidgets(
    'renders overlapping colliders with debug rendering',
    (tester) => expectGolden(
      tester,
      'goldens/collider_overlap.png',
      CollisionDetectionNode(
        children: [
          ShapeNode(
            shape: .circle,
            paint: Paint()..color = RED.withValues(alpha: 0.5),
            size: Vector2(40, 40),
            anchor: .center(),
            position: Vector2(-15, -15),
            children: [
              ColliderNode(
                shape: .circle,
                size: Vector2(40, 40),
                anchor: .center(),
              ),
            ],
          ),
          ShapeNode(
            shape: .rectangle,
            paint: Paint()..color = BLUE.withValues(alpha: 0.5),
            size: Vector2(50, 50),
            anchor: .center(),
            position: Vector2(15, 15),
            children: [
              ColliderNode(
                shape: .rectangle,
                size: Vector2(50, 50),
                anchor: .center(),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
