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
      Entity(
        opacity: 0.5,
        children: [
          Entity(
            shape: .square(40),
            position: .all(10),
            components: [ShapeComponent(shape: .square(40), paint: Paint()..color = RED)],
          ),
          Entity(
            shape: .square(40),
            position: .all(30),
            components: [ShapeComponent(shape: .square(40), paint: Paint()..color = RED)],
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
      Entity(
        opacity: 0.5,
        position: .new(20, 10),
        children: [
          Entity(
            shape: .square(20),
            components: [ShapeComponent(shape: .square(20), paint: Paint()..color = RED)],
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
      Entity(
        opacity: 0.5,
        children: [
          Entity(
            opacity: 0.5,
            children: [
              Entity(
                shape: .square(50),
                position: .all(25),
                components: [ShapeComponent(shape: .square(50), paint: Paint()..color = RED)],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
