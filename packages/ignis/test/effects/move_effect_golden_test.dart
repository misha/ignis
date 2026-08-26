import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/expect.dart';

void main() {
  setUpAll(() async {
    Ignis.cache.clear();
    await Preload.run(
      loaders: [ImageLoader()],
      paths: ['test/assets/fire.png'],
    );
  });

  testWidgets(
    'moves a sprite by an offset',
    (tester) => expectGolden(
      tester,
      'goldens/move_effect_by.png',
      SpriteNode(
        sprite: SpriteAnimation('test/assets/fire.png', .new(32, 48), fps: 0),
        anchor: .center,
        position: .all(50),
        children: [
          MoveEffect.by(
            offset: .new(20, -10),
            controller: .duration(1),
          ),
        ],
      )..play(0, frame: 4),
      dt: 1,
      debug: .spatial,
    ),
  );
}
