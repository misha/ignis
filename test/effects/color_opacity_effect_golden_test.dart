import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/expect.dart';

void main() {
  setUpAll(() async {
    Ignis.cache.clear();
    await Preload.run(loaders: [.image()], paths: ['test/assets/fire.png']);
  });

  testWidgets(
    'fades a sprite out to half opacity',
    (tester) {
      final paint = Paint();

      return expectGolden(
        tester,
        'goldens/color_opacity_effect_fade_out.png',
        SpriteNode(
          sprite: SpriteSheet('test/assets/fire.png', .new(32, 48), fps: 0),
          anchor: .center,
          position: .all(50),
          paint: paint,
          children: [
            ColorOpacityEffect.fadeOut(
              paint: paint,
              controller: .duration(1),
            ),
          ],
        )..play(frame: 4),
        dt: 0.5,
      );
    },
  );
}
