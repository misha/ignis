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
    'anchors a sprite to a destination',
    (tester) => expectGoldenGif(
      tester,
      'goldens/anchor_effect_to.gif',
      SpriteNode(
        sprite: SpriteImage('test/assets/key_gold.png'),
        position: .all(50),
        children: [
          AnchorEffect.to(
            destination: .center,
            controller: .duration(1),
          ),
        ],
      ),
      debug: .spatial,
    ),
  );
}
