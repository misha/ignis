import 'package:flutter/widgets.dart';
import 'package:ignis/ignis.dart';

import '../demo_scene.dart';
import 'sprites.dart';

/// The demos on the Debugging page, by the name their `<Demo/>` slot carries.
final Map<String, Widget Function()> debuggingDemos = {
  'debug-wireframes': () {
    return DemoScene(
      assets: const ['assets/sheets/slime_idle.png'],
      builder: _WireframesEntity.new,
    );
  },
};

/// A slime for the overlay to outline.
class _WireframesEntity extends Entity {
  _WireframesEntity() : super(position: DEMO_SIZE / 2);

  @override
  void process(Message message) {
    super.process(message);

    // demo on debug-wireframes
    switch (message) {
      case Build():
        components.add(
          SpriteComponent(
            sprite: SpriteAnimation(
              'assets/sheets/slime_idle.png',
              SLIME_SIZE,
              fps: 16,
            ),
            anchor: .center,
          ),
        );
    }
    // demo off
  }
}
