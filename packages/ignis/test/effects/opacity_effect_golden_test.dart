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

  testWidgets('fades a whole subtree out as one image', (tester) {
    return expectGoldenGif(
      tester,
      'goldens/opacity_effect_fade_out.gif',
      OpacityNode(
        children: [
          SpriteNode(
            sprite: SpriteImage('test/assets/key_gold.png'),
            anchor: .center,
            position: .new(40, 50),
          ),
          SpriteNode(
            sprite: SpriteImage('test/assets/key_gold.png'),
            anchor: .center,
            position: .new(60, 50),
          ),
          OpacityEffect.fadeOut(timeline: .duration(1)),
        ],
      ),
    );
  });
}
