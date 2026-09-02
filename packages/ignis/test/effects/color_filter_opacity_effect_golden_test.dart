import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/colors.dart';
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
    'tints a sprite in with a color filter',
    (tester) {
      final paint = Paint();

      return expectGoldenGif(
        tester,
        'goldens/color_filter_opacity_effect_fade_in.gif',
        SpriteNode(
          sprite: SpriteImage('test/assets/key_gold.png'),
          anchor: .center,
          position: .all(50),
          paint: paint,
          children: [
            ColorFilterOpacityEffect.fadeIn(
              paint: paint,
              color: BLUE,
              controller: .duration(1),
            ),
          ],
        ),
        debug: .spatial,
      );
    },
  );
}
