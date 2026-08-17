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
      sprite: SpriteSheet('assets/sheets/bonfire.png', BONFIRE_SIZE, fps: 16),
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
      sprite: SpriteSheet('assets/sheets/bonfire_smoke.png', BONFIRE_SIZE, fps: 10),
    );

    final flame = SpriteNode(
      sprite: SpriteSheet('assets/sheets/bonfire_flame.png', BONFIRE_SIZE, fps: 16),
    );

    final wood = SpriteNode(
      sprite: SpriteSheet('assets/sheets/bonfire_wood.png', BONFIRE_SIZE, fps: 6),
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
    final slime = SpriteNode(
      sprite: SpriteSheet(
        'assets/sheets/slime.png',
        SLIME_SIZE,
        fps: 16,
        rows: [
          .new(frames: 14),
          .new(frames: 30),
          .new(frames: 25),
          .new(frames: 17),
          .new(frames: 30),
          .new(frames: 12),
          .new(frames: 13),
          .new(frames: 13),
          .new(frames: 45),
          .new(frames: 27),
          .new(frames: 49),
        ],
      ),
    );

    final taps = TapInput(shape: .rectangle(DEMO_SIZE));

    taps.onTap(() => slime.play(row: (slime.row + 1) % slime.sprite.rows));
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
    final slime = SpriteNode(
      sprite: SpriteSheet(
        'assets/sheets/slime.png',
        SLIME_SIZE,
        fps: 16,
        rows: [
          .new(key: 'idle', frames: 14),
          .new(key: 'jump', frames: 30),
        ],
      ),
    );

    final taps = TapInput(shape: .rectangle(DEMO_SIZE));

    taps.onTap(() => slime.play(key: slime.row == 0 ? 'jump' : 'idle'));
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

/// Two sprites on one sheet, each playing a row that sets its own rate.
class _RatesNode extends Node {
  @override
  void build() {
    super.build();

    // demo on sprite-rates
    final sheet = SpriteSheet(
      'assets/sheets/slime.png',
      SLIME_SIZE,
      fps: 16,
      rows: [
        .new(frames: 14, fps: 5),
        .new(frames: 30),
      ],
    );

    final idle = SpriteNode(sprite: sheet);
    final jump = SpriteNode(sprite: sheet)..play(row: 1);
    // demo off

    add(
      BoxNode(
        alignment: .center,
        children: [
          RowNode(
            mainAxisSize: .min,
            children: [idle, jump],
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
    final slime = SpriteNode(
      sprite: SpriteSheet(
        'assets/sheets/slime.png',
        SLIME_SIZE,
        fps: 12,
        rows: [
          .new(start: 6, frames: 6),
        ],
      ),
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
    final slime = SpriteNode(
      sprite: SpriteSheet(
        'assets/sheets/slime.png',
        SLIME_SIZE,
        fps: 0,
        rows: [
          .timed([0.8, 0.06, 0.06, 0.06, 0.06, 0.06]),
        ],
      ),
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
    final sheet = SpriteSheet('assets/sheets/bonfire.png', BONFIRE_SIZE, fps: 16);

    final fire = SpriteNode(sprite: sheet);
    final embers = SpriteNode(sprite: sheet, speed: 0.25);
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
      sprite: SpriteGroup([
        SpriteImage('assets/images/bonfire.png', key: 'fire'),
        SpriteSheet.single('assets/sheets/slime_jump.png', SLIME_SIZE, fps: 16, key: 'slime'),
      ]),
    );

    final taps = TapInput(shape: .rectangle(DEMO_SIZE));

    taps.onTap(() => creature.play(key: creature.row == 0 ? 'slime' : 'fire'));
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
          sprite: SpriteSheet(
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

    final log1 = DemoLog();
    final log2 = DemoLog();

    // demo on sprite-signals
    final slime = SpriteNode(
      sprite: SpriteSheet('assets/sheets/slime_jump.png', SLIME_SIZE, fps: 16),
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
