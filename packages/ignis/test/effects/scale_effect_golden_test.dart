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
    'scales a sprite by an offset',
    (tester) => expectGoldenGif(
      tester,
      'goldens/scale_effect_by.gif',
      SpriteNode(
        sprite: SpriteImage('test/assets/key_gold.png'),
        anchor: .center,
        position: .all(50),
        children: [
          ScaleEffect.by(
            offset: .all(0.5),
            timeline: .duration(1),
          ),
        ],
      ),
      debug: .spatial,
    ),
  );
}
