import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/expect.dart';

void main() {
  setUpAll(() async {
    Ignis.cache.clear();
    await Preload.run(loaders: [.image()], paths: ['test/assets/fire.png']);
  });

  testWidgets(
    'rotates a sprite by an angle',
    (tester) => expectGolden(
      tester,
      'goldens/rotate_effect_by.png',
      SpriteNode(
        sprite: SpriteAnimation('test/assets/fire.png', .new(32, 48), fps: 0),
        anchor: .center,
        position: .all(50),
        children: [
          RotateEffect.by(
            angle: math.pi / 2,
            controller: .duration(1),
          ),
        ],
      )..play(0, frame: 4),
      dt: 1,
      debug: .spatial,
    ),
  );
}
