import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/colors.dart';
import '../support/images.dart';
import '../support/test_sink.dart';

void main() {
  test('starts on the first frame of the first row', () async {
    final animation = SpriteAnimation(await solidAsset(8, 4, RED), .all(4), fps: 0);
    final sprite = SpriteComponent(sprite: animation);
    Scene(Entity(components: [sprite]));

    expect(sprite.sprite, same(animation));
    expect((sprite.current.index, sprite.current.frame), (0, 0));
    expect((sprite.shape.width, sprite.shape.height), (4.0, 4.0));
  });

  test('play switches the row and frame', () async {
    final sheet = SpriteSheet(await solidAsset(6, 6, BLUE), .all(2));
    final slime = sheet.animations(fps: 0);
    final sprite = SpriteComponent(sprite: slime);

    sprite.play(2, frame: 1);

    expect((sprite.current.index, sprite.current.frame), (2, 1));

    Scene(Entity(components: [sprite]));

    expect((sprite.current.index, sprite.current.frame), (2, 1));
  });

  test('takes its size from the frame, not the image', () async {
    final sprite = SpriteComponent(
      sprite: SpriteAnimation(await solidAsset(8, 4, RED), .all(4), fps: 0),
    );

    Scene(Entity(components: [sprite]));

    expect(sprite.shape.size, Vector2.all(4));
  });

  test('renders the frame it is playing', () async {
    final sheet = SpriteSheet(
      await pixelAsset([
        [RED, GREEN],
        [BLUE, WHITE],
      ]),
      .all(1),
    );

    final sprite = SpriteComponent(sprite: sheet.animations(fps: 0));
    final entity = Entity(components: [sprite]);
    Scene(entity);

    var image = await renderImage(entity, sprite.shape.width.ceil(), sprite.shape.height.ceil());
    expect(await pixelAt(image, 0, 0), RED);

    sprite.play(1, frame: 1);

    expect((sprite.current.index, sprite.current.frame), (1, 1));
    image = await renderImage(entity, sprite.shape.width.ceil(), sprite.shape.height.ceil());
    expect(await pixelAt(image, 0, 0), WHITE);
  });

  test('plays straight through the parts of a group', () async {
    final group = SpriteGroup([
      SpriteImage(await solidAsset(8, 4, RED)),
      SpriteAnimation(
        await pixelAsset([
          [BLUE, GREEN],
        ]),
        .all(1),
        fps: 0,
      ),
    ]);

    final sprite = SpriteComponent(sprite: group);
    final entity = Entity(components: [sprite]);
    Scene(entity);

    expect(sprite.shape.size, Vector2(8, 4));

    sprite.play(1);

    expect(sprite.shape.size, Vector2.all(1), reason: 'a part brings its own frame size');

    final image = await renderImage(entity, sprite.shape.width.ceil(), sprite.shape.height.ceil());
    expect(await pixelAt(image, 0, 0), BLUE);
  });

  test('plays a row of its own frames, at its own rate', () async {
    final a = Entity();

    final sprite = SpriteComponent(
      sprite: SpriteAnimation(
        await solidAsset(8, 2, RED),
        .all(2),
        end: 2,
        fps: 4,
      ),
    );

    a.components.add(sprite);
    final scene = Scene(a);

    scene.update(0.25);
    expect(sprite.current.frame, 1);

    scene.update(0.25);
    expect(sprite.current.frame, 0, reason: 'a two-frame row wraps at its own length');
  });

  test('holds each frame for its own duration', () async {
    final a = Entity();

    final sprite = SpriteComponent(
      sprite: SpriteAnimation.timed(
        await solidAsset(6, 2, RED),
        .all(2),
        [0.5, 0.2, 0.2],
      ),
    );

    a.components.add(sprite);
    final scene = Scene(a);

    scene.update(0.4);
    expect(sprite.current.frame, 0, reason: 'the first frame is held for half a second');

    scene.update(0.2);
    expect(sprite.current.frame, 1);

    scene.update(0.15);
    expect(sprite.current.frame, 2);
  });

  test('reports its size once it builds', () async {
    final sink = TestSink([
      SpriteComponent(
        sprite: SpriteAnimation(await solidAsset(8, 4, RED), .all(4), fps: 0),
      ),
    ]);

    Scene(sink);

    expect(sink.of<SpriteResize>().single.sprite.shape.size, Vector2.all(4));
  });

  test('reports a change of size, and only a change', () async {
    final sprite = SpriteMap({
      'small': SpriteAnimation(await solidAsset(2, 2, RED), .all(2), fps: 0),
      'same': SpriteAnimation(await solidAsset(2, 2, BLUE), .all(2), fps: 0),
      'large': SpriteAnimation(await solidAsset(4, 4, GREEN), .all(4), fps: 0),
    });

    final component = SpriteComponent(sprite: sprite);
    final sink = TestSink([component]);
    Scene(sink);
    sink.received.clear();

    component.play('same');
    expect(sink.of<SpriteResize>(), isEmpty);

    component.play('large');
    expect(sink.of<SpriteResize>().single.sprite.shape.size, Vector2.all(4));
  });

  test('scales the rate its sprite states', () async {
    final a = Entity();

    final sprite = SpriteComponent(
      sprite: SpriteAnimation(await solidAsset(8, 4, RED), .all(4), fps: 2),
      speed: 0.5,
    );

    a.components.add(sprite);
    final scene = Scene(a);

    scene.update(0.5);
    expect(sprite.current.frame, 0, reason: 'half speed halves the advance');

    scene.update(0.5);
    expect(sprite.current.frame, 1);
  });

  test('holds the current frame at no speed', () async {
    final a = Entity();

    final sprite = SpriteComponent(
      sprite: SpriteAnimation(await solidAsset(8, 4, RED), .all(4), fps: 2),
      speed: 0,
    );

    a.components.add(sprite);
    final scene = Scene(a);

    scene.update(10);
    expect(sprite.current.frame, 0);
  });

  test('rejects a negative speed', () async {
    final animation = SpriteAnimation(await solidAsset(8, 4, RED), .all(4), fps: 0);

    expect(() => SpriteComponent(sprite: animation, speed: -1), throwsAssertionError);
  });

  test('advances to the next entry, wrapping past the last', () async {
    final sheet = SpriteSheet(await solidAsset(4, 6, RED), .all(2));
    final sprite = SpriteComponent(sprite: sheet.animations(fps: 0));

    sprite.play(0, frame: 1);
    sprite.playNext();

    expect((sprite.current.index, sprite.current.frame), (1, 0));

    sprite.playNext();
    expect(sprite.current.index, 2);

    sprite.playNext();
    expect(sprite.current.index, 0);
  });

  test('steps back to the entry before, wrapping past the first', () async {
    final sheet = SpriteSheet(await solidAsset(4, 6, RED), .all(2));
    final sprite = SpriteComponent(sprite: sheet.animations(fps: 0));

    sprite.playPrevious();
    expect(sprite.current.index, 2);

    sprite.playPrevious();
    expect(sprite.current.index, 1);
  });

  test('walks the names a map holds', () async {
    final sprite = SpriteComponent(
      sprite: SpriteMap({
        'idle': SpriteAnimation(await solidAsset(4, 2, RED), .all(2), fps: 0),
        'jump': SpriteAnimation(await solidAsset(4, 2, BLUE), .all(2), fps: 0),
      }),
    );

    sprite.playNext();
    expect(sprite.current.key, 'jump');

    sprite.playNext();
    expect(sprite.current.key, 'idle');

    sprite.playPrevious();
    expect(sprite.current.key, 'jump');
  });

  test('plays the entry a key names', () async {
    final sprite = SpriteComponent(
      sprite: SpriteMap({
        'idle': SpriteAnimation(await solidAsset(4, 2, RED), .all(2), fps: 8),
        'jump': SpriteAnimation(await solidAsset(4, 2, BLUE), .all(2), fps: 8),
      }),
    );

    sprite.play('jump');

    expect(sprite.current.index, 1);
  });

  test('rejects a key nothing answers to', () async {
    final sprite = SpriteComponent(
      sprite: SpriteMap({
        'idle': SpriteAnimation(await solidAsset(4, 2, RED), .all(2), fps: 8),
      }),
    );

    expect(() => sprite.play('jump'), throwsArgumentError);
  });

  test('rejects a frame the row does not hold', () async {
    final sprite = SpriteComponent(
      sprite: SpriteAnimation(await solidAsset(8, 4, RED), .all(4), fps: 0),
    );

    expect(() => sprite.play(0, frame: 2), throwsArgumentError);
    expect(() => sprite.play(1), throwsArgumentError);
  });

  test('finishes a row that says it does not loop', () async {
    final a = Entity();

    final sprite = SpriteComponent(
      sprite: SpriteAnimation(
        await solidAsset(8, 4, RED),
        .all(4),
        fps: 2,
        loop: false,
      ),
    );

    a.components.add(sprite);
    final scene = Scene(a);

    scene.update(1);
    expect(sprite.current.isFinished, isTrue);
  });

  test('play overrides what the row says about looping', () async {
    final a = Entity();
    final sprite = SpriteComponent(
      sprite: SpriteAnimation(await solidAsset(8, 4, RED), .all(4), fps: 2),
    );
    a.components.add(sprite);
    final scene = Scene(a);

    sprite.play(0, loop: false);
    expect(sprite.current.loops, isFalse);

    scene.update(1);
    expect(sprite.current.isFinished, isTrue);

    sprite.play(0);
    expect(sprite.current.loops, isTrue, reason: 'a bare play clears the override');

    scene.update(10);
    expect(sprite.current.isFinished, isFalse);
  });

  test('re-resolves its sprite when the cache changes', () async {
    addTearDown(Ignis.cache.clear);

    Ignis.cache.add('sheet.png', await solidImage(8, 4, RED));
    final sprite = SpriteComponent(sprite: SpriteAnimation('sheet.png', .all(4), fps: 0));
    Scene(Entity(components: [sprite]));

    // Twice as wide.
    Ignis.cache.add('sheet.png', await solidImage(16, 4, RED));

    expect(sprite.sprite.entries[0].frames, 4);
  });

  test('holds a row the replacement no longer reaches', () async {
    addTearDown(Ignis.cache.clear);

    Ignis.cache.add('sheet.png', await solidImage(4, 4, RED));

    final sheet = SpriteSheet('sheet.png', .all(2));
    final sprite = SpriteComponent(sprite: sheet.animations(fps: 0));
    Scene(Entity(components: [sprite]));

    sprite.play(1, frame: 1);
    final held = sprite.sprite.entries[1].image;

    // One row shorter.
    Ignis.cache.add('sheet.png', await solidImage(4, 2, RED));

    expect((sprite.current.index, sprite.current.frame), (1, 1));
    expect(sprite.sprite.entries[1].image, same(held), reason: 'row 1 keeps its image');
    expect(sprite.sprite.entries[0].image, isNot(same(held)), reason: 'row 0 reloads');
  });

  test('does not detach once finished, by default', () async {
    final a = Entity();
    final animation = SpriteAnimation(
      await solidAsset(8, 4, RED),
      .all(4),
      fps: 2,
      loop: false,
    );
    final sprite = SpriteComponent(sprite: animation);
    a.components.add(sprite);
    final scene = Scene(a);

    scene.update(1);
    expect(sprite.current.isFinished, isTrue);

    scene.update(0);
    expect(a.components, [sprite]);
  });

  test('detaches itself once finished, when cleanup is true', () async {
    final a = Entity();
    final animation = SpriteAnimation(
      await solidAsset(8, 4, RED),
      .all(4),
      fps: 2,
      loop: false,
    );
    final sprite = SpriteComponent(sprite: animation, cleanup: true);
    a.components.add(sprite);
    final scene = Scene(a);

    scene.update(1);
    expect(sprite.current.isFinished, isTrue);
    expect(a.components, [sprite]); // Still pending.

    scene.update(0);
    expect(a.components, isEmpty);
  });

  test('ignores cleanup while looping, since a looping sprite never finishes', () async {
    final a = Entity();
    final animation = SpriteAnimation(await solidAsset(8, 4, RED), .all(4), fps: 2);
    final sprite = SpriteComponent(sprite: animation, cleanup: true);
    a.components.add(sprite);
    final scene = Scene(a);

    scene.update(10);
    expect(sprite.current.isFinished, isFalse);
    expect(a.components, [sprite]);
  });
}
