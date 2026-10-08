import 'package:flutter/widgets.dart';
import 'package:ignis/ignis.dart';

import '../demo_scene.dart';
import 'sprites.dart';

/// The demos on the Debugging page, by the name their `<Demo/>` slot carries.
final Map<String, Widget Function()> debuggingDemos = {
  'debug-wireframes': () {
    return DemoScene(
      assets: const [
        'assets/sheets/slime_idle.png',
        'assets/sheets/slime_death.png',
        'assets/sheets/slime_recover.png',
      ],
      builder: _WireframesNode.new,
    );
  },
};

/// A slime beside a hit area nothing draws, which only the overlay shows.
class _WireframesNode extends Node {
  late SpriteNode slime;
  late TapInput taps;

  @override
  void process(Message message) {
    super.process(message);

    // demo on debug-wireframes
    switch (message) {
      case Build():
        slime = SpriteNode(
          sprite: SpriteMap({
            'idle': SpriteAnimation(
              'assets/sheets/slime_idle.png',
              SLIME_SIZE,
              fps: 16,
            ),
            'death': SpriteAnimation(
              'assets/sheets/slime_death.png',
              SLIME_SIZE,
              fps: 16,
              loop: false,
            ),
            'recover': SpriteAnimation(
              'assets/sheets/slime_recover.png',
              SLIME_SIZE,
              fps: 16,
              loop: false,
            ),
          }),
          anchor: .centerRight,
          position: DEMO_SIZE / 2 - .new(8, 0),
        );

        taps = TapInput(
          shape: .rectangle(.all(28)),
          anchor: .centerLeft,
          position: DEMO_SIZE / 2 + .new(8, 0),
        );

      case Tap():
        taps.enabled = false;
        slime.play('death');

      case SpriteFinish():
        switch (slime.current.key) {
          case 'death':
            slime.play('recover');

          case 'recover':
            slime.play('idle');
            taps.enabled = true;
        }
    }
    // demo off

    switch (message) {
      case Build():
        addAll([slime, taps]);
    }
  }
}
