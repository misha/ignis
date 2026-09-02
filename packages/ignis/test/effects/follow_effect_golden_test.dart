import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/colors.dart';
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
    'chases a marker at a constant speed, landing on it and re-chasing when it jumps',
    (tester) async {
      final marker = ShapeNode(
        shape: .square(6),
        position: .new(80, 50),
        paint: Paint()..color = BLUE,
      );

      final follower = SpriteNode(
        sprite: SpriteImage('test/assets/key_gold.png'),
        position: .new(10, 50),
        children: [FollowEffect(following: marker, speed: 80)],
      );

      await expectGoldenGif(
        tester,
        'goldens/follow_effect.gif',
        Node(children: [marker, follower]),
        frames: 15,
        debug: .spatial,
        onFrame: (frame) {
          if (frame == 8) marker.position.setValues(40, 10);
        },
      );
    },
  );
}
