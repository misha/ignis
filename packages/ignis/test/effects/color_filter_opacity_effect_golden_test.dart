import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/colors.dart';
import '../support/expect.dart';

void main() {
  setUpAll(() async {
    Ignis.cache.clear();
    await Preload.run(loaders: [.image()], paths: ['test/assets/fire.png']);
  });

  testWidgets(
    'tints a sprite in with a color filter',
    (tester) {
      final paint = Paint();

      return expectGolden(
        tester,
        'goldens/color_filter_opacity_effect_fade_in.png',
        SpriteNode(
          sprite: SpriteAnimation('test/assets/fire.png', .new(32, 48), fps: 0),
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
        )..play(0, frame: 4),
        dt: 1,
        debug: .spatial,
      );
    },
  );
}
