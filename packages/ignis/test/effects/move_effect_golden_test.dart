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
    'moves a sprite by an offset',
    (tester) => expectGoldenGif(
      tester,
      'goldens/move_effect_by.gif',
      SpriteNode(
        sprite: SpriteImage('test/assets/key_gold.png'),
        anchor: .center,
        position: .all(50),
        children: [
          MoveEffect.by(
            offset: .new(20, -10),
            controller: .duration(1),
          ),
        ],
      ),
      debug: .spatial,
    ),
  );
}
