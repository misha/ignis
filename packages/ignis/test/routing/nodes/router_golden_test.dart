import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../../support/colors.dart';
import '../../support/expect.dart';

void main() {
  RouterNode<String> game() {
    return RouterNode(
      router: Router(),
      children: [
        RouteNode(
          name: 'game',
          children: [
            ShapeNode(
              shape: .square(100),
              paint: Paint()..color = RED,
            ),
            ShapeNode(
              shape: .square(20),
              paint: Paint()..color = YELLOW,
              position: .all(40),
            ),
          ],
        ),
        RouteNode(
          name: 'menu',
          children: [
            ShapeNode(
              shape: .square(60),
              paint: Paint()..color = BLUE,
              position: .all(20),
            ),
          ],
        ),
      ],
    );
  }

  testWidgets('a push slides a panel over a frozen route', (tester) async {
    final host = game();

    await expectGoldenGif(
      tester,
      'goldens/router_push.gif',
      host,
      onFrame: (frame) {
        if (frame == 0) host.router.push('menu', transition: SlideTransition());
      },
    );
  });

  testWidgets('a pop slides the panel back out', (tester) async {
    final host = game();

    await expectGoldenGif(
      tester,
      'goldens/router_pop.gif',
      host,
      onFrame: (frame) {
        if (frame == 0) host.router.push('menu', transition: SlideTransition());
        if (frame == 4) host.router.pop();
      },
    );
  });
}
