import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../../support/colors.dart';
import '../../support/expect.dart';

void main() {
  ({RouterNode game, RouteNode menu}) stage() {
    return (
      game: RouterNode(
        children: [
          RouteNode(
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
        ],
      ),
      menu: RouteNode(
        transition: SlideTransition(),
        children: [
          ShapeNode(
            shape: .square(60),
            paint: Paint()..color = BLUE,
            position: .all(20),
          ),
        ],
      ),
    );
  }

  testWidgets('a push slides a panel over a frozen route', (tester) async {
    final (:game, :menu) = stage();
    game.push(menu);

    await expectGoldenGif(
      tester,
      'goldens/router_push.gif',
      game,
    );
  });

  testWidgets('a pop slides the panel back out', (tester) async {
    final (:game, :menu) = stage();
    game.push(menu);

    await expectGoldenGif(
      tester,
      'goldens/router_pop.gif',
      game,
      onFrame: (frame) {
        if (frame == 5) game.pop();
      },
    );
  });
}
