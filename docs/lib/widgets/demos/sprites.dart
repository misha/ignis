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
  'sprite-finish': () {
    return DemoScene(
      assets: const ['assets/sheets/explosion.png'],
      builder: _ExplosionsNode.new,
    );
  },
};

/// An image with no grid to it, drawn as a single frame.
///
/// Each demo marks off the sprite it is about, and the page shows that much.
/// Mounting the node and centering it stay out of the region: true of every
/// scene, and nothing to do with sprites.
class _StillNode extends Node {
  @override
  void build() {
    super.build();

    // #region sprite-still
    final fire = SpriteNode(sheet: .asset('assets/images/bonfire.png'));
    // #endregion

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

    // #region sprite-animation
    final fire = SpriteNode(
      sheet: .asset('assets/sheets/bonfire.png', size: BONFIRE_SIZE),
      fps: 16,
    );
    // #endregion

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

    // #region sprite-layers
    // One fire in three sheets, each keeping its own clock: the smoke drifts,
    // the flame runs, and the logs barely move.
    final smoke = SpriteNode(
      sheet: .asset('assets/sheets/bonfire_smoke.png', size: BONFIRE_SIZE),
      fps: 10,
    );

    final flame = SpriteNode(
      sheet: .asset('assets/sheets/bonfire_flame.png', size: BONFIRE_SIZE),
      fps: 16,
    );

    final wood = SpriteNode(
      sheet: .asset('assets/sheets/bonfire_wood.png', size: BONFIRE_SIZE),
      fps: 6,
    );
    // #endregion

    // Smoke behind, the flame over it, the logs in front.
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

    // #region sprite-split
    // Three sheets, each its own animation and its own length: fourteen frames
    // of idling, thirty of jumping.
    final slime = SpriteNode.split(
      sheets: [
        .asset('assets/sheets/slime_idle.png', size: SLIME_SIZE),
        .asset('assets/sheets/slime_jump.png', size: SLIME_SIZE),
        .asset('assets/sheets/slime_spit.png', size: SLIME_SIZE),
      ],
      fps: 16,
    );

    // Tapping moves on to the next sheet.
    var playing = 0;
    final taps = TapInput(shape: .rectangle(DEMO_SIZE));

    taps.onTap(() {
      playing = (playing + 1) % slime.sheets;
      slime.play(sheet: playing);
    });
    // #endregion

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

    // #region sprite-finish
    final taps = TapInput(shape: .rectangle(DEMO_SIZE));

    taps.onTapDown((event) {
      add(
        SpriteNode(
          sheet: .asset('assets/sheets/explosion.png', size: EXPLOSION_SIZE),
          fps: 20,
          loop: false,
          cleanup: true,
          position: event.scene,
          anchor: .bottomCenter,
        ),
      );
    });
    // #endregion

    add(taps);
  }
}
