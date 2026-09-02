import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/colors.dart';
import '../support/expect.dart';

void main() {
  setUp(() {
    Ignis.controls = Controls();
  });

  testWidgets(
    'a push slides a panel over a live backdrop that keeps playing',
    (tester) async {
      final game = ShapeNode(
        shape: .square(100),
        paint: Paint()..color = RED,
        children: [
          ShapeNode(
            shape: .square(20),
            paint: Paint()..color = YELLOW,
            position: .new(10, 80),
            children: [VelocityEffect(velocity: .new(40, 0))],
          ),
        ],
      );

      final menu = ShapeNode(
        shape: .square(60),
        paint: Paint()..color = BLUE,
        position: .all(20),
      );

      final router = RouterNode(initial: game);

      await expectGoldenGif(
        tester,
        'goldens/router_push.gif',
        router,
        onFrame: (frame) {
          if (frame == 0) {
            router.push(
              menu,
              backdrop: .live,
              transition: (to, from) => SlideTransitionEffect(to, from, duration: 0.5),
            );
          }
        },
      );
    },
  );

  testWidgets(
    'a go mid-flight force-finishes before the next transition plays',
    (tester) async {
      final game = ShapeNode(shape: .square(100), paint: Paint()..color = RED);
      final menu = ShapeNode(shape: .square(100), paint: Paint()..color = BLUE);
      final settings = ShapeNode(shape: .square(100), paint: Paint()..color = GREEN);
      final router = RouterNode(initial: game);

      await expectGoldenGif(
        tester,
        'goldens/router_interrupt.gif',
        router,
        onFrame: (frame) {
          if (frame == 0) {
            router.go(menu, transition: (to, from) => SlideTransitionEffect(to, from, duration: 1));
          }

          if (frame == 4) {
            router.go(
              settings,
              transition: (to, from) => SlideTransitionEffect(to, from, direction: .left, duration: 0.5),
            );
          }
        },
      );
    },
  );
}
