import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/expect.dart';

void main() {
  setUpAll(() async {
    Ignis.cache.clear();
    await Preload.run([.image()], paths: ['test/assets/fire.png']);
  });

  testWidgets(
    'anchors a sprite to a destination',
    (tester) => expectGolden(
      tester,
      'goldens/anchor_effect_to.png',
      SpriteNode(
        sheet: .asset('test/assets/fire.png', size: .new(32, 48)),
        position: .all(50),
        children: [
          AnchorEffect.to(
            destination: .center,
            controller: .duration(1),
          ),
        ],
      )..play(column: 4),
      dt: 1,
    ),
  );
}
