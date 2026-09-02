import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/colors.dart';
import '../support/expect.dart';

void main() {
  testWidgets(
    'a fading layer composites overlapping children as one image',
    (tester) => expectGolden(
      tester,
      'goldens/opacity_fade.png',
      OpacityNode(
        opacity: 0.5,
        children: [
          ShapeNode(
            shape: .square(40),
            position: .all(10),
            paint: Paint()..color = RED,
          ),
          ShapeNode(
            shape: .square(40),
            position: .all(30),
            paint: Paint()..color = RED,
          ),
        ],
      ),
    ),
  );

  testWidgets(
    'a fading layer applies its transform inside the layer',
    (tester) => expectGolden(
      tester,
      'goldens/opacity_transform.png',
      OpacityNode(
        opacity: 0.5,
        position: .new(20, 10),
        children: [
          ShapeNode(
            shape: .square(20),
            paint: Paint()..color = RED,
          ),
        ],
      ),
    ),
  );

  testWidgets(
    'nested layers multiply their opacities',
    (tester) => expectGolden(
      tester,
      'goldens/opacity_nested.png',
      OpacityNode(
        opacity: 0.5,
        children: [
          OpacityNode(
            opacity: 0.5,
            children: [
              ShapeNode(
                shape: .square(50),
                position: .all(25),
                paint: Paint()..color = RED,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
