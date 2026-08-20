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
  @override
  void build() {
    super.build();

    // demo on debug-wireframes
    final slime = SpriteNode(
      sprite: SpriteGroup([
        SpriteSheet.single(
          'assets/sheets/slime_idle.png',
          SLIME_SIZE,
          fps: 16,
          id: 'idle',
        ),
        SpriteSheet.single(
          'assets/sheets/slime_death.png',
          SLIME_SIZE,
          fps: 16,
          id: 'death',
          loop: false,
        ),
        SpriteSheet.single(
          'assets/sheets/slime_recover.png',
          SLIME_SIZE,
          fps: 16,
          id: 'recover',
          loop: false,
        ),
      ]),
    );

    final taps = TapInput(shape: .rectangle(.all(28)));

    taps.onTap(() {
      taps.enabled = false;
      slime.play(id: 'death');
    });

    slime.onFinish(() {
      switch (slime.current.id) {
        case 'death':
          slime.play(id: 'recover');

        case 'recover':
          slime.play(id: 'idle');
          taps.enabled = true;
      }
    });
    // demo off

    add(
      BoxNode(
        alignment: .center,
        children: [
          RowNode(
            mainAxisSize: .min,
            crossAxisAlignment: .center,
            spacing: 16,
            children: [slime, taps],
          ),
        ],
      ),
    );
  }
}
