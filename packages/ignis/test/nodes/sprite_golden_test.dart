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
    'renders the selected sprite frame',
    (tester) => expectGolden(
      tester,
      'goldens/sprite_frame.png',
      SpriteNode(
        sprite: SpriteAnimation(
          'test/assets/fire.png',
          .new(32, 48),
          fps: 0,
        ),
      )..play(0, frame: 4),
      debug: .spatial,
    ),
  );

  testWidgets(
    'plays its animation, wrapping at the end of the row',
    (tester) => expectGoldenGif(
      tester,
      'goldens/sprite_playback.gif',
      SpriteNode(
        sprite: SpriteAnimation(
          'test/assets/fire.png',
          .new(32, 48),
          fps: 8,
        ),
      )..play(0),
      debug: .spatial,
    ),
  );
}
