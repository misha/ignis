import 'package:flutter/widgets.dart';
import 'package:ignis/ignis.dart';

import '../demo_scene.dart';

/// One frame of a bonfire sheet.
const BONFIRE_SIZE = Vector2(55, 79);

/// One frame of any of the slime's sheets.
const SLIME_SIZE = Vector2.all(56);

/// The demos on the Sprites page, by the name their `<Demo/>` slot carries.
final Map<String, Widget Function()> spriteDemos = {
  'sprite-still': () {
    return DemoScene(
      assets: const ['assets/images/bonfire.png'],
      builder: _StillEntity.new,
    );
  },
  'sprite-animation': () {
    return DemoScene(
      assets: const ['assets/sheets/bonfire.png'],
      builder: _BonfireEntity.new,
    );
  },
  'sprite-layers': () {
    return DemoScene(
      assets: const [
        'assets/sheets/bonfire_wood.png',
        'assets/sheets/bonfire_flame.png',
        'assets/sheets/bonfire_smoke.png',
      ],
      builder: _LayeredEntity.new,
    );
  },
  'sprite-rates': () {
    return DemoScene(
      assets: const ['assets/sheets/slime.png'],
      builder: _RatesEntity.new,
    );
  },
  'sprite-tiles': () {
    return DemoScene(
      assets: const ['assets/sheets/slime.png'],
      builder: _TilesEntity.new,
    );
  },
  'sprite-partial': () {
    return DemoScene(
      assets: const ['assets/sheets/slime.png'],
      builder: _PartialEntity.new,
    );
  },
  'sprite-timed': () {
    return DemoScene(
      assets: const ['assets/sheets/slime.png'],
      builder: _TimedEntity.new,
    );
  },
  'sprite-speed': () {
    return DemoScene(
      assets: const ['assets/sheets/bonfire.png'],
      builder: _SpeedEntity.new,
    );
  },
};

/// An entity drawing [sprite] with its [anchor] on the center.
Entity _sprite(
  SpriteComponent sprite, {
  Anchor anchor = .center,
}) {
  return Entity(
    position: DEMO_SIZE / 2,
    components: [sprite..anchor = anchor],
  );
}

/// An image with no grid to it, drawn as a single frame.
class _StillEntity extends Entity {
  @override
  void process(Message message) {
    super.process(message);

    switch (message) {
      case Build():
        // demo on sprite-still
        final fire = SpriteComponent(sprite: SpriteImage('assets/images/bonfire.png'));
        // demo off

        add(_sprite(fire));
    }
  }
}

/// The same fire, cut into twenty frames and played on a loop.
class _BonfireEntity extends Entity {
  @override
  void process(Message message) {
    super.process(message);

    switch (message) {
      case Build():
        // demo on sprite-animation
        final fire = SpriteComponent(
          sprite: SpriteAnimation(
            'assets/sheets/bonfire.png',
            BONFIRE_SIZE,
            fps: 16,
          ),
        );
        // demo off

        add(_sprite(fire));
    }
  }
}

/// One fire out of three sheets, each running at its own speed.
class _LayeredEntity extends Entity {
  @override
  void process(Message message) {
    super.process(message);

    switch (message) {
      case Build():
        // demo on sprite-layers
        final smoke = SpriteComponent(
          sprite: SpriteAnimation(
            'assets/sheets/bonfire_smoke.png',
            BONFIRE_SIZE,
            fps: 10,
          ),
          anchor: .center,
        );

        final flame = SpriteComponent(
          sprite: SpriteAnimation(
            'assets/sheets/bonfire_flame.png',
            BONFIRE_SIZE,
            fps: 16,
          ),
          anchor: .center,
        );

        final wood = SpriteComponent(
          sprite: SpriteAnimation(
            'assets/sheets/bonfire_wood.png',
            BONFIRE_SIZE,
            fps: 6,
          ),
          anchor: .center,
        );
        // demo off

        add(
          Entity(
            position: DEMO_SIZE / 2,
            components: [smoke, flame, wood],
          ),
        );
    }
  }
}

/// One row of a sheet, taken twice and played at two rates.
class _RatesEntity extends Entity {
  @override
  void process(Message message) {
    super.process(message);

    switch (message) {
      case Build():
        // demo on sprite-rates
        final sheet = SpriteSheet('assets/sheets/slime.png', SLIME_SIZE);
        final slow = SpriteComponent(sprite: sheet.animation(row: 1, end: 30, fps: 8));
        final fast = SpriteComponent(sprite: sheet.animation(row: 1, end: 30, fps: 24));
        // demo off

        add(_sprite(slow, anchor: .centerRight));
        add(_sprite(fast, anchor: .centerLeft));
    }
  }
}

/// Four cells of the grid, drawn where they sit rather than played.
class _TilesEntity extends Entity {
  @override
  void process(Message message) {
    super.process(message);

    switch (message) {
      case Build():
        // demo on sprite-tiles
        final sheet = SpriteSheet('assets/sheets/slime.png', SLIME_SIZE);

        final crouch = SpriteComponent(sprite: sheet.image(row: 1, column: 0));
        final launch = SpriteComponent(sprite: sheet.image(row: 1, column: 9));
        final peak = SpriteComponent(sprite: sheet.image(row: 1, column: 18));
        final land = SpriteComponent(sprite: sheet.image(row: 1, column: 27));
        // demo off

        add(_sprite(crouch, anchor: .bottomRight));
        add(_sprite(launch, anchor: .bottomLeft));
        add(_sprite(peak, anchor: .topRight));
        add(_sprite(land, anchor: .topLeft));
    }
  }
}

/// Six frames out of the middle of a row.
class _PartialEntity extends Entity {
  @override
  void process(Message message) {
    super.process(message);

    switch (message) {
      case Build():
        // demo on sprite-partial
        final sheet = SpriteSheet('assets/sheets/slime.png', SLIME_SIZE);

        final slime = SpriteComponent(
          sprite: sheet.animation(
            row: 0, // idle
            start: 6,
            end: 12,
            fps: 12,
          ),
        );
        // demo off

        add(_sprite(slime));
    }
  }
}

/// A row that hangs on its first frame, then runs out the rest.
class _TimedEntity extends Entity {
  @override
  void process(Message message) {
    super.process(message);

    switch (message) {
      case Build():
        // demo on sprite-timed
        final sheet = SpriteSheet('assets/sheets/slime.png', SLIME_SIZE);

        final slime = SpriteComponent(
          sprite: sheet.timed([0.8, 0.06, 0.06, 0.06, 0.06, 0.06]), // idle
        );
        // demo off

        add(_sprite(slime));
    }
  }
}

/// One sheet at the rate it was drawn for, and at a quarter of it.
class _SpeedEntity extends Entity {
  @override
  void process(Message message) {
    super.process(message);

    switch (message) {
      case Build():
        // demo on sprite-speed
        final bonfire = SpriteAnimation(
          'assets/sheets/bonfire.png',
          BONFIRE_SIZE,
          fps: 16,
        );

        final fire = SpriteComponent(sprite: bonfire);
        final embers = SpriteComponent(sprite: bonfire, speed: 0.25);
        // demo off

        add(_sprite(fire, anchor: .centerRight));
        add(_sprite(embers, anchor: .centerLeft));
    }
  }
}
