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
            size: .all(40),
            anchor: .center(),
            position: .all(25),
            children: [
              ColliderNode(
                shape: .circle,
                size: .all(40),
                anchor: .center(),
              ),
            ],
          ),
          ShapeNode(
            shape: .rectangle,
            paint: Paint()..color = BLUE.withValues(alpha: 0.5),
            size: .all(50),
            anchor: .center(),
            position: .all(55),
            children: [
              ColliderNode(
                shape: .rectangle,
                size: .all(50),
                anchor: .center(),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
