import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

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
    'moves a sprite by an offset',
    (tester) => expectGolden(
      tester,
      'goldens/move_effect_by.png',
      SpriteNode(
        sheet: .asset('test/assets/fire.png', size: .new(32, 48)),
        anchor: .center,
        position: .all(50),
        children: [
          MoveEffect.by(
            offset: .new(20, -10),
            controller: .duration(1),
          ),
        ],
      )..play(column: 4),
      dt: 1,
    ),
  );
}
