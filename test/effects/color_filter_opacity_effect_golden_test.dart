import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/colors.dart';
import '../support/expect.dart';

void main() {
  setUpAll(() async {
    Ignis.cache.clear();
    final preload = Preload();
    preload.loader(.image());
    final request = preload.load(paths: ['test/assets/fire.png']);
    await request;
    request.dispose();
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
