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
    'moves a sprite at a constant velocity',
    (tester) => expectGoldenGif(
      tester,
      'goldens/velocity_effect.gif',
      SpriteNode(
        sprite: SpriteImage('test/assets/key_gold.png'),
        anchor: .center,
        position: .new(20, 30),
        children: [VelocityEffect(velocity: .new(40, 20))],
      ),
      debug: .spatial,
    ),
  );
}
