import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/colors.dart';
import '../support/images.dart';

void main() {
  test('starts on the first frame of the first row', () async {
    final sheet = SpriteSheet(await solidAsset(8, 4, RED), .all(4), fps: 0);
    final node = SpriteNode(sprite: sheet);
    node.mount();

    expect(node.sprite, same(sheet));
    expect((node.current.index, node.current.frame), (0, 0));
    expect((node.width, node.height), (4.0, 4.0));
  });

  test('play switches the row and frame', () async {
    final sheet = SpriteSheet(await solidAsset(6, 6, BLUE), .all(2), fps: 0);
    final node = SpriteNode(sprite: sheet);

    node.play(index: 2, frame: 1);

    expect((node.current.index, node.current.frame), (2, 1));

    node.mount();

    expect((node.current.index, node.current.frame), (2, 1));
  });

  test('takes its size from the frame, not the image', () async {
    final node = SpriteNode(
      sprite: SpriteSheet(await solidAsset(8, 4, RED), .all(4), fps: 0),
    );

    node.mount();

    expect(node.size, Vector2.all(4));
  });

  test('renders the frame it is playing', () async {
    final sheet = SpriteSheet(
      await pixelAsset([
        [RED, GREEN],
        [BLUE, WHITE],
      ]),
      .all(1),
      fps: 0,
    );

    final node = SpriteNode(sprite: sheet);
    node.mount();

    var image = await renderImage(node, node.width.ceil(), node.height.ceil());
    expect(await pixelAt(image, 0, 0), RED);

    node.play(index: 1, frame: 1);

    expect((node.current.index, node.current.frame), (1, 1));
    image = await renderImage(node, node.width.ceil(), node.height.ceil());
    expect(await pixelAt(image, 0, 0), WHITE);
  });

  test('plays straight through the parts of a group', () async {
    final group = SpriteGroup([
      SpriteImage(await solidAsset(8, 4, RED)),
      SpriteSheet(
        await pixelAsset([
          [BLUE, GREEN],
        ]),
        .all(1),
        fps: 0,
      ),
    ]);

    final node = SpriteNode(sprite: group);
    node.mount();

    expect(node.size, Vector2(8, 4));

    node.play(index: 1);

    expect(node.size, Vector2.all(1), reason: 'a part brings its own frame size');

    final image = await renderImage(node, node.width.ceil(), node.height.ceil());
    expect(await pixelAt(image, 0, 0), BLUE);
  });

  test('plays a row of its own frames, at its own rate', () async {
    final a = Node();

    final node = SpriteNode(
      sprite: SpriteSheet(
        await solidAsset(8, 2, RED),
        .all(2),
        fps: 10,
        rows: [
          .new(frames: 2, fps: 4),
        ],
      ),
    );

    a.add(node);
    final scene = a.mount();

    scene.update(0.25);
    expect(node.current.frame, 1);

    scene.update(0.25);
    expect(node.current.frame, 0, reason: 'a two-frame row wraps at its own length');
  });

  test('holds each frame for its own duration', () async {
    final a = Node();

    final node = SpriteNode(
      sprite: SpriteSheet(
        await solidAsset(6, 2, RED),
        .all(2),
        fps: 0,
        rows: [
          .timed([0.5, 0.2, 0.2]),
        ],
      ),
    );

    a.add(node);
    final scene = a.mount();

    scene.update(0.4);
    expect(node.current.frame, 0, reason: 'the first frame is held for half a second');

    scene.update(0.2);
    expect(node.current.frame, 1);

    scene.update(0.15);
    expect(node.current.frame, 2);
  });

  test('emits the frame index within its row', () async {
    final a = Node();

    final node = SpriteNode(
      sprite: SpriteSheet(
        await pixelAsset([
          [RED, GREEN],
          [BLUE, WHITE],
        ]),
        .all(1),
        fps: 4,
      ),
    );

    final frames = <int>[];
    var loops = 0;
    node.onFrame(frames.add);
    node.onLoop(() => loops += 1);
    node.play(index: 1);

    a.add(node);
    final scene = a.mount();

    scene.update(0.5);

    expect(frames, [1, 0]);
    expect(loops, 1);
  });

  test('scales the rate its sprite states', () async {
    final a = Node();

    final node = SpriteNode(
      sprite: SpriteSheet(await solidAsset(8, 4, RED), .all(4), fps: 2),
      speed: 0.5,
    );

    a.add(node);
    final scene = a.mount();

    scene.update(0.5);
    expect(node.current.frame, 0, reason: 'half speed halves the advance');

    scene.update(0.5);
    expect(node.current.frame, 1);
  });

  test('holds the current frame at no speed', () async {
    final a = Node();

    final node = SpriteNode(
      sprite: SpriteSheet(await solidAsset(8, 4, RED), .all(4), fps: 2),
      speed: 0,
    );

    a.add(node);
    final scene = a.mount();

    scene.update(10);
    expect(node.current.frame, 0);
  });

  test('rejects a negative speed', () async {
    final sheet = SpriteSheet(await solidAsset(8, 4, RED), .all(4), fps: 0);

    expect(() => SpriteNode(sprite: sheet, speed: -1), throwsAssertionError);
  });

  test('plays the row a key names', () async {
    final node = SpriteNode(
      sprite: SpriteSheet(
        await solidAsset(4, 4, RED),
        .all(2),
        fps: 8,
        rows: [
          .new(id: 'idle'),
          .new(id: 'jump'),
        ],
      ),
    );

    node.play(id: 'jump');

    expect(node.current.index, 1);
  });

  test('rejects a key no row answers to', () async {
    final node = SpriteNode(
      sprite: SpriteSheet(
        await solidAsset(4, 4, RED),
        .all(2),
        fps: 8,
        rows: [
          .new(id: 'idle'),
        ],
      ),
    );

    expect(() => node.play(id: 'jump'), throwsArgumentError);
  });

  test('rejects a frame the row does not hold', () async {
    final node = SpriteNode(
      sprite: SpriteSheet(await solidAsset(8, 4, RED), .all(4), fps: 0),
    );

    expect(() => node.play(frame: 2), throwsArgumentError);
    expect(() => node.play(index: 1), throwsArgumentError);
  });

  test('finishes a row that says it does not loop', () async {
    final a = Node();

    final node = SpriteNode(
      sprite: SpriteSheet(
        await solidAsset(8, 4, RED),
        .all(4),
        fps: 2,
        rows: [
          .new(loop: false),
        ],
      ),
    );

    a.add(node);
    final scene = a.mount();

    scene.update(1);
    expect(node.current.isFinished, isTrue);
  });

  test('play overrides what the row says about looping', () async {
    final a = Node();
    final node = SpriteNode(sprite: SpriteSheet(await solidAsset(8, 4, RED), .all(4), fps: 2));
    a.add(node);
    final scene = a.mount();

    node.play(loop: false);
    expect(node.current.loops, isFalse);

    scene.update(1);
    expect(node.current.isFinished, isTrue);

    node.play();
    expect(node.current.loops, isTrue, reason: 'a bare play clears the override');

    scene.update(10);
    expect(node.current.isFinished, isFalse);
  });

  test('reassemble re-resolves its sprite', () async {
    addTearDown(Ignis.cache.clear);

    Ignis.cache.add('sheet.png', await solidImage(8, 4, RED));
    final node = SpriteNode(sprite: SpriteSheet('sheet.png', .all(4), fps: 0));

    // Twice as wide.
    Ignis.cache.add('sheet.png', await solidImage(16, 4, RED));

    node.reassemble();

    expect(node.sprite.frames(0), 4);
  });

  test('reassemble clamps a row the replacement no longer has', () async {
    addTearDown(Ignis.cache.clear);

    Ignis.cache.add('sheet.png', await solidImage(4, 4, RED));
    final node = SpriteNode(sprite: SpriteSheet('sheet.png', .all(2), fps: 0));
    node.play(index: 1, frame: 1);

    // One row shorter.
    Ignis.cache.add('sheet.png', await solidImage(4, 2, RED));

    node.reassemble();

    expect((node.current.index, node.current.frame), (0, 0));
  });

  test('does not detach once finished, by default', () async {
    final a = Node();
    final sheet = SpriteSheet(await solidAsset(8, 4, RED), .all(4), fps: 2, loop: false);
    final node = SpriteNode(sprite: sheet);
    a.add(node);
    final scene = a.mount();

    scene.update(1);
    expect(node.current.isFinished, isTrue);

    scene.update(0);
    expect(a.children, [node]);
  });

  test('detaches itself once finished, when cleanup is true', () async {
    final a = Node();
    final sheet = SpriteSheet(await solidAsset(8, 4, RED), .all(4), fps: 2, loop: false);
    final node = SpriteNode(sprite: sheet, cleanup: true);
    a.add(node);
    final scene = a.mount();

    scene.update(1);
    expect(node.current.isFinished, isTrue);
    expect(a.children, [node]); // Still pending.

    scene.update(0);
    expect(a.children, isEmpty);
  });

  test('ignores cleanup while looping, since a looping sprite never finishes', () async {
    final a = Node();
    final sheet = SpriteSheet(await solidAsset(8, 4, RED), .all(4), fps: 2);
    final node = SpriteNode(sprite: sheet, cleanup: true);
    a.add(node);
    final scene = a.mount();

    scene.update(10);
    expect(node.current.isFinished, isFalse);
    expect(a.children, [node]);
  });
}
