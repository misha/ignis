import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/colors.dart';
import '../support/expect.dart';

void main() {
  SpatialNode screen(Color color) {
    return SpatialNode(
      children: [
        ShapeNode(
          shape: .square(100),
          paint: Paint()..color = color,
        ),
      ],
    );
  }

  testWidgets('a curtain fades through black around the swap', (tester) async {
    final from = screen(RED);
    final to = screen(BLUE);

    await expectGoldenGif(
      tester,
      'goldens/curtain.gif',
      Node(children: [from, to, CurtainTransitionEffect(to, from)]),
    );
  });

  testWidgets('a curtain honors its color and swap point', (tester) async {
    final from = screen(RED);
    final to = screen(BLUE);

    await expectGoldenGif(
      tester,
      'goldens/curtain_custom.gif',
      Node(
        children: [
          from,
          to,
          CurtainTransitionEffect(to, from, color: GREEN, swapAt: 0.8),
        ],
      ),
    );
  });

  testWidgets('a wipe sweeps right', (tester) async {
    final from = screen(RED);
    final to = screen(BLUE);

    await expectGoldenGif(
      tester,
      'goldens/wipe_right.gif',
      Node(children: [from, to, WipeTransitionEffect(to, from)]),
    );
  });

  testWidgets('a wipe sweeps left', (tester) async {
    final from = screen(RED);
    final to = screen(BLUE);

    await expectGoldenGif(
      tester,
      'goldens/wipe_left.gif',
      Node(
        children: [
          from,
          to,
          WipeTransitionEffect(to, from, direction: .left),
        ],
      ),
    );
  });

  testWidgets('a wipe sweeps up', (tester) async {
    final from = screen(RED);
    final to = screen(BLUE);

    await expectGoldenGif(
      tester,
      'goldens/wipe_up.gif',
      Node(
        children: [
          from,
          to,
          WipeTransitionEffect(to, from, direction: .up),
        ],
      ),
    );
  });

  testWidgets('a wipe sweeps down', (tester) async {
    final from = screen(RED);
    final to = screen(BLUE);

    await expectGoldenGif(
      tester,
      'goldens/wipe_down.gif',
      Node(
        children: [
          from,
          to,
          WipeTransitionEffect(to, from, direction: .down),
        ],
      ),
    );
  });

  testWidgets('a slide moves the incoming screen up, pushing the outgoing one ahead', (
    tester,
  ) async {
    final from = SpatialNode(
      children: [
        screen(RED),
        ShapeNode(
          shape: .square(20),
          paint: Paint()..color = YELLOW,
          position: .all(40),
        ),
      ],
    );

    final to = screen(BLUE);

    await expectGoldenGif(
      tester,
      'goldens/slide_up.gif',
      Node(children: [from, to, SlideTransitionEffect(to, from)]),
    );
  });

  testWidgets('a slide moves the incoming screen down', (tester) async {
    final from = screen(RED);
    final to = screen(BLUE);

    await expectGoldenGif(
      tester,
      'goldens/slide_down.gif',
      Node(
        children: [
          from,
          to,
          SlideTransitionEffect(to, from, direction: .down),
        ],
      ),
    );
  });

  testWidgets('a slide moves the incoming screen left', (tester) async {
    final from = screen(RED);
    final to = screen(BLUE);

    await expectGoldenGif(
      tester,
      'goldens/slide_left.gif',
      Node(
        children: [
          from,
          to,
          SlideTransitionEffect(to, from, direction: .left),
        ],
      ),
    );
  });

  testWidgets('a slide moves the incoming screen right', (tester) async {
    final from = screen(RED);
    final to = screen(BLUE);

    await expectGoldenGif(
      tester,
      'goldens/slide_right.gif',
      Node(
        children: [
          from,
          to,
          SlideTransitionEffect(to, from, direction: .right),
        ],
      ),
    );
  });

  testWidgets('a slide leaves a standing overlay in place below', (tester) async {
    final below = SpatialNode(
      children: [
        screen(RED),
        ShapeNode(
          shape: .square(20),
          paint: Paint()..color = YELLOW,
          position: .all(40),
        ),
      ],
    );

    final to = screen(BLUE);

    await expectGoldenGif(
      tester,
      'goldens/slide_overlay.gif',
      Node(children: [below, to, SlideTransitionEffect(to, null)]),
    );
  });

  testWidgets('fades the incoming layer over an unfaded outgoing one', (tester) async {
    final from = screen(RED);
    final to = screen(BLUE);

    await expectGoldenGif(
      tester,
      'goldens/fade.gif',
      Node(children: [from, to, FadeTransitionEffect(to, from)]),
    );
  });

  testWidgets('a crossfade dips both layers', (tester) async {
    final from = screen(RED);
    final to = screen(BLUE);

    await expectGoldenGif(
      tester,
      'goldens/fade_crossfade.gif',
      Node(children: [from, to, FadeTransitionEffect(to, from, crossFade: true)]),
    );
  });
}
