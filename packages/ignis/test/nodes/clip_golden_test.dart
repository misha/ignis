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
      ClipNode(
        shape: .square(50),
        position: .all(25),
        children: [ShapeNode(shape: .square(100), paint: Paint()..color = RED)],
      ),
    ),
  );
}
