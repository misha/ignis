import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/colors.dart';
import '../support/expect.dart';

void main() {
  TransitionNode<String> stage({
    Iterable<Node> red = const [],
    Iterable<Node> blue = const [],
  }) {
    return TransitionNode(
      children: [
        TransitionGroupNode(
          name: 'red',
          children: [
            ShapeNode(
              shape: .square(100),
              paint: Paint()..color = RED,
            ),
            ...red,
          ],
        ),
        TransitionGroupNode(
          name: 'blue',
          children: [
            ShapeNode(
              shape: .square(100),
              paint: Paint()..color = BLUE,
            ),
            ...blue,
          ],
        ),
      ],
    );
  }

  testWidgets('a cut trades instantly', (tester) async {
    final host = stage();

    await expectGoldenGif(
      tester,
      'goldens/cut.gif',
      host,
      onFrame: (frame) {
        if (frame == 0) host.show('blue', transition: CutTransition());
      },
    );
  });

  testWidgets('a slide turns around when shown its origin mid-flight', (tester) async {
    final host = stage();

    await expectGoldenGif(
      tester,
      'goldens/slide_reversed.gif',
      host,
      onFrame: (frame) {
        if (frame == 0) host.show('blue', transition: SlideTransition());
        if (frame == 4) host.show('red');
      },
    );
  });

  testWidgets(
    'a curtain fades through black around the swap',
    (tester) => expectGoldenGif(
      tester,
      'goldens/curtain.gif',
      stage()..show(
        'blue',
        transition: CurtainTransition(
          veil: ShapeNode(
            paint: Paint()..color = BLACK,
          ),
        ),
      ),
    ),
  );

  testWidgets(
    'a curtain honors its color and swap point',
    (tester) => expectGoldenGif(
      tester,
      'goldens/curtain_custom.gif',
      stage()..show(
        'blue',
        transition: CurtainTransition(
          veil: ShapeNode(
            paint: Paint()..color = GREEN,
          ),
          swapAt: 0.8,
        ),
      ),
    ),
  );

  testWidgets(
    'a wipe sweeps right',
    (tester) => expectGoldenGif(
      tester,
      'goldens/wipe_right.gif',
      stage()..show(
        'blue',
        transition: WipeTransition(
          panel: ShapeNode(
            paint: Paint()..color = BLACK,
          ),
        ),
      ),
    ),
  );

  testWidgets(
    'a wipe sweeps left',
    (tester) => expectGoldenGif(
      tester,
      'goldens/wipe_left.gif',
      stage()..show(
        'blue',
        transition: WipeTransition(
          panel: ShapeNode(
            paint: Paint()..color = BLACK,
          ),
          direction: .left,
        ),
      ),
    ),
  );

  testWidgets(
    'a wipe sweeps up',
    (tester) => expectGoldenGif(
      tester,
      'goldens/wipe_up.gif',
      stage()..show(
        'blue',
        transition: WipeTransition(
          panel: ShapeNode(
            paint: Paint()..color = BLACK,
          ),
          direction: .up,
        ),
      ),
    ),
  );

  testWidgets(
    'a wipe sweeps down',
    (tester) => expectGoldenGif(
      tester,
      'goldens/wipe_down.gif',
      stage()..show(
        'blue',
        transition: WipeTransition(
          panel: ShapeNode(
            paint: Paint()..color = BLACK,
          ),
          direction: .down,
        ),
      ),
    ),
  );

  testWidgets(
    'a slide moves the incoming screen up, pushing the outgoing one ahead',
    (tester) => expectGoldenGif(
      tester,
      'goldens/slide_up.gif',
      stage(
        red: [
          ShapeNode(
            shape: .square(20),
            paint: Paint()..color = YELLOW,
            position: .all(40),
          ),
        ],
      )..show('blue', transition: SlideTransition()),
    ),
  );

  testWidgets(
    'a slide moves the incoming screen down',
    (tester) => expectGoldenGif(
      tester,
      'goldens/slide_down.gif',
      stage()..show(
        'blue',
        transition: SlideTransition(direction: .down),
      ),
    ),
  );

  testWidgets(
    'a slide moves the incoming screen left',
    (tester) => expectGoldenGif(
      tester,
      'goldens/slide_left.gif',
      stage()..show(
        'blue',
        transition: SlideTransition(direction: .left),
      ),
    ),
  );

  testWidgets(
    'a slide moves the incoming screen right',
    (tester) => expectGoldenGif(
      tester,
      'goldens/slide_right.gif',
      stage()..show(
        'blue',
        transition: SlideTransition(direction: .right),
      ),
    ),
  );

  testWidgets(
    'fades the incoming layer over an unfaded outgoing one',
    (tester) => expectGoldenGif(
      tester,
      'goldens/fade.gif',
      stage()..show('blue', transition: FadeTransition()),
    ),
  );

  testWidgets(
    'a crossfade dips both layers',
    (tester) => expectGoldenGif(
      tester,
      'goldens/fade_crossfade.gif',
      stage()..show(
        'blue',
        transition: FadeTransition(crossFade: true),
      ),
    ),
  );

  testWidgets(
    'a wipe carries its panel',
    (tester) => expectGoldenGif(
      tester,
      'goldens/wipe_panel.gif',
      stage()..show(
        'blue',
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
      ),
    ),
  );

  testWidgets(
    'a curtain fades through its veil',
    (tester) => expectGoldenGif(
      tester,
      'goldens/curtain_veil.gif',
      stage()..show(
        'blue',
        transition: CurtainTransition(
          veil: ShapeNode(
            shape: .square(50),
            paint: Paint()..color = GREEN,
            position: .all(25),
          ),
        ),
      ),
    ),
  );

  testWidgets(
    'a slide inside a clipped region stays inside it',
    (tester) => expectGoldenGif(
      tester,
      'goldens/slide_clipped.gif',
      ClipNode(
        shape: .rectangle(.new(60, 40)),
        position: .new(20, 30),
        children: [stage()..show('blue', transition: SlideTransition())],
      ),
    ),
  );
}
