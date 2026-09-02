import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/expect.dart';

void main() {
  setUpAll(() async {
    Ignis.cache.clear();
    await Preload.run(
      loaders: [ImageLoader()],
      paths: ['test/assets/key_gold.png'],
    );
  });

  testWidgets(
    'rotates a sprite by an angle',
    (tester) => expectGoldenGif(
      tester,
      'goldens/rotate_effect_by.gif',
      SpriteNode(
        sprite: SpriteImage('test/assets/key_gold.png'),
        anchor: .center,
        position: .all(50),
        children: [
          RotateEffect.by(
            angle: math.pi / 2,
            timeline: .duration(1),
          ),
        ],
      ),
      debug: .spatial,
    ),
  );
}
