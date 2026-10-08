import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/colors.dart';
import '../support/expect.dart';

void main() {
  testWidgets(
    'clips its subtree to its shape',
    (tester) => expectGolden(
      tester,
      'goldens/clip.png',
      Entity(
        shape: .square(50),
        position: .all(25),
        clip: true,
        children: [
          Entity(
            shape: .square(100),
            components: [
              ShapeComponent(
                shape: .square(100),
                paint: Paint()..color = RED,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
