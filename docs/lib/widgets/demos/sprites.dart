import 'package:flutter/widgets.dart';
import 'package:ignis/ignis.dart';

import '../colors.dart';
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
  'sprite-rows': () {
    return DemoScene(
      assets: const ['assets/sheets/slime.png'],
      builder: _PackedNode.new,
    );
  },
  'sprite-keys': () {
    return DemoScene(
      assets: const ['assets/sheets/slime.png'],
      builder: _KeyedNode.new,
    );
  },
  'sprite-rates': () {
    return DemoScene(
      assets: const ['assets/sheets/slime.png'],
      builder: _RatesNode.new,
    );
  },
  'sprite-tiles': () {
    return DemoScene(
      assets: const ['assets/sheets/slime.png'],
      builder: _TilesNode.new,
    );
  },
  'sprite-partial': () {
    return DemoScene(
      assets: const ['assets/sheets/slime.png'],
      builder: _PartialNode.new,
    );
  },
  'sprite-timed': () {
    return DemoScene(
      assets: const ['assets/sheets/slime.png'],
      builder: _TimedNode.new,
    );
  },
  'sprite-speed': () {
    return DemoScene(
      assets: const ['assets/sheets/bonfire.png'],
      builder: _SpeedNode.new,
    );
  },
  'sprite-group': () {
    return DemoScene(
      assets: const [
        'assets/images/bonfire.png',
        'assets/sheets/slime_jump.png',
      ],
      builder: _GroupNode.new,
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
    final fire = SpriteNode(sprite: SpriteImage('assets/images/bonfire.png'));
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
      sprite: SpriteAnimation(
        'assets/sheets/bonfire.png',
        BONFIRE_SIZE,
        fps: 16,
      ),
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
      sprite: SpriteAnimation(
        'assets/sheets/bonfire_smoke.png',
        BONFIRE_SIZE,
        fps: 10,
      ),
    );

    final flame = SpriteNode(
      sprite: SpriteAnimation(
        'assets/sheets/bonfire_flame.png',
        BONFIRE_SIZE,
        fps: 16,
      ),
    );

    final wood = SpriteNode(
      sprite: SpriteAnimation(
        'assets/sheets/bonfire_wood.png',
        BONFIRE_SIZE,
        fps: 6,
      ),
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

/// Eleven animations of different lengths, packed into one grid.
class _PackedNode extends Node {
  @override
  void build() {
    super.build();

    // demo on sprite-rows
    final sheet = SpriteSheet('assets/sheets/slime.png', SLIME_SIZE);

    final slime = SpriteNode(
      sprite: sheet.animations(
        fps: 16,
        rows: [
          .new(end: 14), // idle
          .new(end: 30), // jump
          .new(end: 25), // jump_forward
          .new(end: 17), // spit
          .new(end: 30), // spike
          .new(end: 12), // injured1
          .new(end: 13), // injured2
          .new(end: 13), // injured3
          .new(end: 45), // splat_wall
          .new(end: 27), // recover
          .new(end: 49), // death
        ],
      ),
    );

    final taps = TapInput(shape: .rectangle(DEMO_SIZE));
    taps.onTap(slime.playNext);
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

/// Rows that answer to a name, played by it.
class _KeyedNode extends Node {
  @override
  void build() {
    super.build();

    // demo on sprite-keys
    final sheet = SpriteSheet('assets/sheets/slime.png', SLIME_SIZE);

    final slime = SpriteNode(
      sprite: SpriteMap({
        'idle': sheet.animation(row: 0, end: 14, fps: 16),
        'jump': sheet.animation(row: 1, end: 30, fps: 16),
      }),
    );

    final taps = TapInput(shape: .rectangle(DEMO_SIZE));
    taps.onTap(() => slime.play(slime.current.key == 'idle' ? 'jump' : 'idle'));
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

/// One row of a sheet, taken twice and played at two rates.
class _RatesNode extends Node {
  @override
  void build() {
    super.build();

    // demo on sprite-rates
    final sheet = SpriteSheet('assets/sheets/slime.png', SLIME_SIZE);

    final slow = SpriteNode(sprite: sheet.animation(row: 1, end: 30, fps: 8));
    final fast = SpriteNode(sprite: sheet.animation(row: 1, end: 30, fps: 24));
    // demo off

    add(
      BoxNode(
        alignment: .center,
        children: [
          RowNode(
            mainAxisSize: .min,
            children: [slow, fast],
          ),
        ],
      ),
    );
  }
}

/// Four cells of the grid, drawn where they sit rather than played.
class _TilesNode extends Node {
  @override
  void build() {
    super.build();

    // demo on sprite-tiles
    final sheet = SpriteSheet('assets/sheets/slime.png', SLIME_SIZE);

    final crouch = SpriteNode(sprite: sheet.image(row: 1, column: 0));
    final launch = SpriteNode(sprite: sheet.image(row: 1, column: 9));
    final peak = SpriteNode(sprite: sheet.image(row: 1, column: 18));
    final land = SpriteNode(sprite: sheet.image(row: 1, column: 27));
    // demo off

    add(
      BoxNode(
        alignment: .center,
        children: [
          ColumnNode(
            mainAxisSize: .min,
            children: [
              RowNode(
                mainAxisSize: .min,
                children: [crouch, launch],
              ),
              RowNode(
                mainAxisSize: .min,
                children: [peak, land],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Six frames out of the middle of a row.
class _PartialNode extends Node {
  @override
  void build() {
    super.build();

    // demo on sprite-partial
    final sheet = SpriteSheet('assets/sheets/slime.png', SLIME_SIZE);

    final slime = SpriteNode(
      sprite: sheet.animation(row: 0, start: 6, end: 12, fps: 12), // idle
    );
    // demo off

    add(
      BoxNode(
        alignment: .center,
        children: [slime],
      ),
    );
  }
}

/// A row that hangs on its first frame, then runs out the rest.
class _TimedNode extends Node {
  @override
  void build() {
    super.build();

    // demo on sprite-timed
    final sheet = SpriteSheet('assets/sheets/slime.png', SLIME_SIZE);

    final slime = SpriteNode(
      sprite: sheet.timed([0.8, 0.06, 0.06, 0.06, 0.06, 0.06]), // idle
    );
    // demo off

    add(
      BoxNode(
        alignment: .center,
        children: [slime],
      ),
    );
  }
}

/// One sheet at the rate it was drawn for, and at a quarter of it.
class _SpeedNode extends Node {
  @override
  void build() {
    super.build();

    // demo on sprite-speed
    final bonfire = SpriteAnimation(
      'assets/sheets/bonfire.png',
      BONFIRE_SIZE,
      fps: 16,
    );

    final fire = SpriteNode(sprite: bonfire);
    final embers = SpriteNode(sprite: bonfire, speed: 0.25);
    // demo off

    add(
      BoxNode(
        alignment: .center,
        children: [
          RowNode(
            mainAxisSize: .min,
            children: [fire, embers],
          ),
        ],
      ),
    );
  }
}

/// A still image and a sheet, numbered as one run of rows.
class _GroupNode extends Node {
  @override
  void build() {
    super.build();

    // demo on sprite-group
    final creature = SpriteNode(
      sprite: SpriteMap({
        'fire': SpriteImage('assets/images/bonfire.png'),
        'slime': SpriteAnimation(
          'assets/sheets/slime_jump.png',
          SLIME_SIZE,
          fps: 16,
        ),
      }),
    );

    final taps = TapInput(shape: .rectangle(DEMO_SIZE));

    taps.onTap(() {
      switch (creature.current.key) {
        case 'fire':
          creature.play('slime');

        case 'slime':
          creature.play('fire');
      }
    });
    // demo off

    addAll([
      BoxNode(
        alignment: .center,
        children: [creature],
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
          sprite: SpriteAnimation(
            'assets/sheets/explosion.png',
            EXPLOSION_SIZE,
            fps: 20,
            loop: false,
          ),
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

    final log = DemoLog();

    // demo on sprite-signals
    final slime = SpriteNode(
      sprite: SpriteAnimation(
        'assets/sheets/slime_jump.png',
        SLIME_SIZE,
        fps: 16,
      ),
    );

    var count = 0;

    slime.onLoop(() => log('onLoop ${count += 1}', ORANGE));
    // demo off

    addAll([
      BoxNode(
        alignment: .center,
        children: [slime],
      ),
      BoxNode(
        padding: .all(4),
        alignment: .topRight,
        children: [log],
      ),
    ]);
  }
}
