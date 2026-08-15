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
    'renders the selected sprite frame',
    (tester) => expectGolden(
      tester,
      'goldens/sprite_frame.png',
      SpriteNode(
        sheet: .asset(
          'test/assets/fire.png',
          size: .new(32, 48),
        ),
      )..play(column: 4),
    ),
  );
}
