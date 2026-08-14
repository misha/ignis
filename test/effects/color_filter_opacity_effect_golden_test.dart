import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/colors.dart';
import '../support/expect.dart';

void main() {
  setUpAll(() async {
    Ignis.cache.clear();
    Spritesheet.clearCache();
    final preload = Preload();
    preload.path(.image(), 'test/assets/fire.png');
    await preload.run();
    await preload.dispose();
  });

  testWidgets(
    'tints a sprite in with a color filter',
    (tester) {
      final paint = Paint();

      return expectGolden(
        tester,
        'goldens/color_filter_opacity_effect_fade_in.png',
        SpriteNode(
          sheet: .asset('test/assets/fire.png', size: .new(32, 48)),
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
        )..play(column: 4),
        dt: 1,
      );
    },
  );
}
