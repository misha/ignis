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
    'spins a sprite at a constant angular speed',
    (tester) => expectGoldenGif(
      tester,
      'goldens/spin_effect.gif',
      SpriteNode(
        sprite: SpriteImage('test/assets/key_gold.png'),
        anchor: .center,
        position: .all(50),
        children: [SpinEffect(speed: math.pi)],
      ),
      debug: .spatial,
    ),
  );
}
