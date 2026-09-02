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
    'fades a sprite out to half opacity',
    (tester) {
      final paint = Paint();

      return expectGoldenGif(
        tester,
        'goldens/color_opacity_effect_fade_out.gif',
        SpriteNode(
          sprite: SpriteImage('test/assets/key_gold.png'),
          anchor: .center,
          position: .all(50),
          paint: paint,
          children: [
            ColorOpacityEffect.fadeOut(
              paint: paint,
              controller: .duration(1),
            ),
          ],
        ),
        debug: .spatial,
      );
    },
  );
}
