import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../../support/colors.dart';
import '../../support/expect.dart';

void main() {
  RouteNode panel(Color color, Iterable<Node> extra) {
    return RouteNode(
      children: [
        ShapeNode(
          shape: .square(100),
          paint: Paint()..color = color,
        ),
        ...extra,
      ],
    );
  }

  /// A router showing red, with a blue route standing by to navigate to.
  ({RouterNode router, RouteNode blue}) stage({
    Iterable<Node> red = const [],
    Iterable<Node> blue = const [],
  }) {
    return (
      router: RouterNode(children: [panel(RED, red)]),
      blue: panel(BLUE, blue),
    );
  }

  testWidgets('a cut trades instantly', (tester) async {
    final (:router, :blue) = stage();

    await expectGoldenGif(
      tester,
      'goldens/cut.gif',
      router,
      onFrame: (frame) {
        if (frame == 0) router.go(blue, transition: CutTransition());
      },
    );
  });

  testWidgets('a curtain fades through black around the swap', (tester) async {
    final (:router, :blue) = stage();

    router.go(
      blue,
      transition: CurtainTransition(
        veil: ShapeNode(
          paint: Paint()..color = BLACK,
        ),
      ),
    );

    await expectGoldenGif(
      tester,
      'goldens/curtain.gif',
      router,
    );
  });

  testWidgets('a curtain honors its color and swap point', (tester) async {
    final (:router, :blue) = stage();

    router.go(
      blue,
      transition: CurtainTransition(
        veil: ShapeNode(
          paint: Paint()..color = GREEN,
        ),
        swapAt: 0.8,
      ),
    );

    await expectGoldenGif(
      tester,
      'goldens/curtain_custom.gif',
      router,
    );
  });

  testWidgets('a wipe sweeps right', (tester) async {
    final (:router, :blue) = stage();

    router.go(
      blue,
      transition: WipeTransition(
        panel: ShapeNode(
          paint: Paint()..color = BLACK,
        ),
      ),
    );

    await expectGoldenGif(
      tester,
      'goldens/wipe_right.gif',
      router,
    );
  });

  testWidgets('a wipe sweeps left', (tester) async {
    final (:router, :blue) = stage();

    router.go(
      blue,
      transition: WipeTransition(
        panel: ShapeNode(
          paint: Paint()..color = BLACK,
        ),
        direction: .left,
      ),
    );

    await expectGoldenGif(
      tester,
      'goldens/wipe_left.gif',
      router,
    );
  });

  testWidgets('a wipe sweeps up', (tester) async {
    final (:router, :blue) = stage();

    router.go(
      blue,
      transition: WipeTransition(
        panel: ShapeNode(
          paint: Paint()..color = BLACK,
        ),
        direction: .up,
      ),
    );

    await expectGoldenGif(
      tester,
      'goldens/wipe_up.gif',
      router,
    );
  });

  testWidgets('a wipe sweeps down', (tester) async {
    final (:router, :blue) = stage();

    router.go(
      blue,
      transition: WipeTransition(
        panel: ShapeNode(
          paint: Paint()..color = BLACK,
        ),
        direction: .down,
      ),
    );

    await expectGoldenGif(
      tester,
      'goldens/wipe_down.gif',
      router,
    );
  });

  testWidgets('a slide moves the incoming screen up, pushing the outgoing one ahead', (
    tester,
  ) async {
    final (:router, :blue) = stage(
      red: [
        ShapeNode(
          shape: .square(20),
          paint: Paint()..color = YELLOW,
          position: .all(40),
        ),
      ],
    );
    router.go(blue, transition: SlideTransition());

    await expectGoldenGif(
      tester,
      'goldens/slide_up.gif',
      router,
    );
  });

  testWidgets('a slide moves the incoming screen down', (tester) async {
    final (:router, :blue) = stage();
    router.go(blue, transition: SlideTransition(direction: .down));

    await expectGoldenGif(
      tester,
      'goldens/slide_down.gif',
      router,
    );
  });

  testWidgets('a slide moves the incoming screen left', (tester) async {
    final (:router, :blue) = stage();
    router.go(blue, transition: SlideTransition(direction: .left));

    await expectGoldenGif(
      tester,
      'goldens/slide_left.gif',
      router,
    );
  });

  testWidgets('a slide moves the incoming screen right', (tester) async {
    final (:router, :blue) = stage();
    router.go(blue, transition: SlideTransition(direction: .right));

    await expectGoldenGif(
      tester,
      'goldens/slide_right.gif',
      router,
    );
  });

  testWidgets('fades the incoming layer over an unfaded outgoing one', (tester) async {
    final (:router, :blue) = stage();
    router.go(blue, transition: FadeTransition());

    await expectGoldenGif(
      tester,
      'goldens/fade.gif',
      router,
    );
  });

  testWidgets('a crossfade dips both layers', (tester) async {
    final (:router, :blue) = stage();
    router.go(blue, transition: FadeTransition(crossFade: true));

    await expectGoldenGif(
      tester,
      'goldens/fade_crossfade.gif',
      router,
    );
  });

  testWidgets('a wipe carries its panel', (tester) async {
    final (:router, :blue) = stage();

    router.go(
      blue,
      transition: WipeTransition(
        panel: ShapeNode(
          paint: Paint()..color = GREEN,
          children: [
            ShapeNode(
              shape: .square(20),
              paint: Paint()..color = YELLOW,
              position: .all(40),
            ),
          ],
        ),
      ),
    );

    await expectGoldenGif(
      tester,
      'goldens/wipe_panel.gif',
      router,
    );
  });

  testWidgets('a curtain fades through its veil', (tester) async {
    final (:router, :blue) = stage();

    router.go(
      blue,
      transition: CurtainTransition(
        veil: ShapeNode(
          shape: .square(50),
          paint: Paint()..color = GREEN,
          position: .all(25),
        ),
      ),
    );

    await expectGoldenGif(
      tester,
      'goldens/curtain_veil.gif',
      router,
    );
  });

  testWidgets('a slide inside a clipped region stays inside it', (tester) async {
    final (:router, :blue) = stage();
    router.go(blue, transition: SlideTransition());

    await expectGoldenGif(
      tester,
      'goldens/slide_clipped.gif',
      ClipNode(
        shape: .rectangle(.new(60, 40)),
        position: .new(20, 30),
        children: [router],
      ),
    );
  });
}
