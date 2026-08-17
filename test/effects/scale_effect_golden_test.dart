import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/expect.dart';

void main() {
  setUpAll(() async {
    Ignis.cache.clear();
    await Preload.run(loaders: [.image()], paths: ['test/assets/fire.png']);
  });

  testWidgets(
    'scales a sprite by an offset',
    (tester) => expectGolden(
      tester,
      'goldens/scale_effect_by.png',
      SpriteNode(
        sheet: .asset('test/assets/fire.png', .new(32, 48)),
        anchor: .center,
        position: .all(50),
        children: [
          ScaleEffect.by(
            offset: .all(0.5),
            controller: .duration(1),
          ),
        ],
      )..play(column: 4),
      dt: 1,
    ),
  );
}
