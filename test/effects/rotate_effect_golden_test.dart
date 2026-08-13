import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/expect.dart';

void main() {
  setUpAll(() async {
    Ignis.cache.clear();
    Spritesheet.clearCache();
    final preload = Preload();
    preload.path(.image(), 'test/assets/fire.png');
    await preload.run();
    await preload.dispose();
  });

  testWidgets(
    'rotates a sprite by an angle',
    (tester) => expectGolden(
      tester,
      '../goldens/rotate_effect_by.png',
      SpriteNode(
        sheet: .asset('test/assets/fire.png', size: .new(32, 48)),
        anchor: .center(),
        position: .all(50),
        children: [
          RotateEffect.by(
            angle: math.pi / 2,
            controller: .duration(1),
          ),
        ],
      )..play(column: 4),
      dt: 1,
    ),
  );
}
