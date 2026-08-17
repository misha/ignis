import 'package:flutter/widgets.dart';
import 'package:ignis/ignis.dart';

import '../demo_scene.dart';

/// One frame of a bonfire sheet.
const BONFIRE_SIZE = Vector2(55, 79);

/// One frame of the explosion sheet.
const EXPLOSION_SIZE = Vector2.all(112);

/// One frame of any of the slime's sheets.
const SLIME_SIZE = Vector2.all(56);

/// The demos on the Sprites page, by the name their `<Demo/>` slot carries.
final Map<String, Widget Function()> spriteDemos = {
  'sprite-still': () {
    return DemoScene(
      assets: const ['assets/images/bonfire.png'],
      builder: _StillNode.new,
    );
  },
  'sprite-animation': () {
    return DemoScene(
      assets: const ['assets/sheets/bonfire.png'],
      builder: _BonfireNode.new,
    );
  },
  'sprite-layers': () {
    return DemoScene(
      assets: const [
        'assets/sheets/bonfire_wood.png',
        'assets/sheets/bonfire_flame.png',
        'assets/sheets/bonfire_smoke.png',
      ],
      builder: _LayeredNode.new,
    );
  },
  'sprite-split': () {
    return DemoScene(
      assets: const [
        'assets/sheets/slime_idle.png',
        'assets/sheets/slime_jump.png',
        'assets/sheets/slime_spit.png',
      ],
      builder: _SlimeNode.new,
    );
  },
  'sprite-signals': () {
    return DemoScene(
      assets: const ['assets/sheets/slime_jump.png'],
      builder: _SignalsNode.new,
    );
  },
  'sprite-finish': () {
    return DemoScene(
      assets: const ['assets/sheets/explosion.png'],
      builder: _ExplosionsNode.new,
    );
  },
};

/// An image with no grid to it, drawn as a single frame.
class _StillNode extends Node {
  @override
  void build() {
    super.build();

    // demo on sprite-still
    final fire = SpriteNode(sheet: .asset('assets/images/bonfire.png'));
    // demo off

    add(
      BoxNode(
        alignment: .center,
        children: [fire],
      ),
    );
  }
}

/// The same fire, cut into twenty frames and played on a loop.
class _BonfireNode extends Node {
  @override
  void build() {
    super.build();

    // demo on sprite-animation
    final fire = SpriteNode(
      sheet: .asset('assets/sheets/bonfire.png', BONFIRE_SIZE),
      fps: 16,
    );
    // demo off

    add(
      BoxNode(
        alignment: .center,
        children: [fire],
      ),
    );
  }
}

/// One fire out of three sheets, each running at its own speed.
class _LayeredNode extends Node {
  @override
  void build() {
    super.build();

    // demo on sprite-layers
    final smoke = SpriteNode(
      sheet: .asset('assets/sheets/bonfire_smoke.png', BONFIRE_SIZE),
      fps: 10,
    );

    final flame = SpriteNode(
      sheet: .asset('assets/sheets/bonfire_flame.png', BONFIRE_SIZE),
      fps: 16,
    );

    final wood = SpriteNode(
      sheet: .asset('assets/sheets/bonfire_wood.png', BONFIRE_SIZE),
      fps: 6,
    );
    // demo off

    add(
      BoxNode(
        alignment: .center,
        children: [smoke, flame, wood],
      ),
    );
  }
}

/// One node holding an animation per sheet, cycled by tapping it.
class _SlimeNode extends Node {
  @override
  void build() {
    super.build();

    // demo on sprite-split
    final slime = SpriteNode.split(
      sheets: [
        .asset('assets/sheets/slime_idle.png', SLIME_SIZE),
        .asset('assets/sheets/slime_jump.png', SLIME_SIZE),
        .asset('assets/sheets/slime_spit.png', SLIME_SIZE),
      ],
      fps: 16,
    );

    var playing = 0;
    final taps = TapInput(shape: .rectangle(DEMO_SIZE));

    taps.onTap(() {
      playing = (playing + 1) % slime.sheets;
      slime.play(sheet: playing);
    });
    // demo off

    addAll([
      BoxNode(
        alignment: .center,
        children: [slime],
      ),
      taps,
    ]);
  }
}

/// A sprite that runs once and takes itself out of the tree.
class _ExplosionsNode extends Node {
  @override
  void build() {
    super.build();

    // demo on sprite-finish
    final taps = TapInput(shape: .rectangle(DEMO_SIZE));

    taps.onTapDown((event) {
      add(
        SpriteNode(
          sheet: .asset('assets/sheets/explosion.png', EXPLOSION_SIZE),
          fps: 20,
          loop: false,
          cleanup: true,
          position: event.scene,
          anchor: .bottomCenter,
        ),
      );
    });
    // demo off

    add(taps);
  }
}

/// A sprite reporting its own progress, with nothing on screen to show for it.
class _SignalsNode extends Node {
  @override
  void build() {
    super.build();

    final log1 = DemoLog();
    final log2 = DemoLog();

    // demo on sprite-signals
    final slime = SpriteNode(
      sheet: .asset('assets/sheets/slime_jump.png', SLIME_SIZE),
      fps: 16,
    );

    var count = 0;

    slime.onFrame((frame) => log1('onFrame $frame'));
    slime.onLoop(() => log2('onLoop ${count += 1}', .orange));
    // demo off

    addAll([
      BoxNode(
        alignment: .center,
        children: [slime],
      ),
      BoxNode(
        padding: .all(4),
        alignment: .topRight,
        children: [
          ColumnNode(
            mainAxisSize: .min,
            crossAxisAlignment: .end,
            spacing: 2,
            children: [log1, log2],
          ),
        ],
      ),
    ]);
  }
}
