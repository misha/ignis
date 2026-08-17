import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import 'support/colors.dart';
import 'support/images.dart';

void main() {
  // Decoding the packed sheet reads through the bundle, which needs a binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Ignis.cache.clear();
  });

  group('SpriteImage', () {
    test('draws the whole image as one frame', () async {
      final image = await solidImage(8, 4);
      Ignis.cache.add('hero.png', image);
      final sprite = SpriteImage('hero.png');

      expect(sprite.image(0), same(image));
      expect(sprite.size(0), Vector2(8, 4));
      expect(sprite.rows, 1);
      expect(sprite.frames(0), 1);
      expect(sprite.rect(0, 0), const Rect.fromLTWH(0, 0, 8, 4));
      expect(sprite.duration(0, 0), double.infinity);
      expect(sprite.loops(0), isFalse);
      expect(sprite.asset, 'hero.png');
      expect(sprite.reload(), same(sprite));
    });

    test('re-resolves against a replaced image', () async {
      Ignis.cache.add('hero.png', await solidImage(8, 4));
      final sprite = SpriteImage('hero.png');
      final replacement = await solidImage(16, 8);
      Ignis.cache.add('hero.png', replacement);

      final reloaded = sprite.reload();

      expect(reloaded, isNot(same(sprite)));
      expect(reloaded.image(0), same(replacement));
      expect(reloaded.size(0), Vector2(16, 8));
    });
  });

  group('SpriteSheet', () {
    test('numbers frames from the start of their row', () async {
      final sheet = SpriteSheet(await solidAsset(4, 6), .all(2), fps: 0);

      expect(sheet.rows, 3);
      expect(sheet.columns, 2);
      expect(
        [
          for (var row = 0; row < sheet.rows; row += 1)
            for (var frame = 0; frame < sheet.frames(row); frame += 1) //
              sheet.rect(row, frame),
        ],
        const [
          Rect.fromLTWH(0, 0, 2, 2),
          Rect.fromLTWH(2, 0, 2, 2),
          Rect.fromLTWH(0, 2, 2, 2),
          Rect.fromLTWH(2, 2, 2, 2),
          Rect.fromLTWH(0, 4, 2, 2),
          Rect.fromLTWH(2, 4, 2, 2),
        ],
      );
    });

    test('copies the supplied frame size', () async {
      final size = MVector2.all(2);
      final sheet = SpriteSheet(await solidAsset(4, 4), size, fps: 0);

      size.splat(1);

      expect(sheet.size(0), Vector2.all(2));
    });

    test('cuts the image cached at its key', () async {
      final image = await solidImage(4, 4);
      Ignis.cache.add('hero.png', image);
      final sheet = SpriteSheet('hero.png', .all(2), fps: 0);

      expect(sheet.image(0), same(image));
      expect(sheet.asset, 'hero.png');
      expect(sheet.rows, 2);
      expect(sheet.frames(0), 2);
    });

    test('requires positive finite frame dimensions', () async {
      final key = await solidAsset(4, 4);

      expect(() => SpriteSheet(key, .new(0, 2), fps: 0), throwsArgumentError);
      expect(() => SpriteSheet(key, .new(2, double.infinity), fps: 0), throwsArgumentError);
    });

    test('requires frame dimensions to divide the image evenly', () async {
      final key = await solidAsset(4, 4);

      expect(() => SpriteSheet(key, .new(3, 2), fps: 0), throwsArgumentError);
      expect(() => SpriteSheet(key, .new(2, 3), fps: 0), throwsArgumentError);
    });

    test('rejects frame indexes outside the row', () async {
      final sheet = SpriteSheet(await solidAsset(4, 4), .all(2), fps: 0);

      expect(() => sheet.rect(0, -1), throwsRangeError);
      expect(() => sheet.rect(0, 2), throwsRangeError);
      expect(() => sheet.rect(2, 0), throwsRangeError);
    });
  });

  group('SheetRow', () {
    test('plays every column after its start', () async {
      final sheet = SpriteSheet(
        await solidAsset(8, 2),
        .all(2),
        fps: 0,
        rows: [
          .new(start: 1),
        ],
      );

      expect(sheet.frames(0), 3);
      expect(sheet.rect(0, 0), const Rect.fromLTWH(2, 0, 2, 2));
      expect(sheet.rect(0, 2), const Rect.fromLTWH(6, 0, 2, 2));
    });

    test('pads the rows it was not given with the sheet defaults', () async {
      final sheet = SpriteSheet(
        await solidAsset(8, 6),
        .all(2),
        fps: 4,
        rows: [
          .new(frames: 2, fps: 8),
        ],
      );

      expect(sheet.frames(0), 2);
      expect(sheet.frames(1), 4);
      expect(sheet.frames(2), 4);
      expect(sheet.duration(0, 0), 1 / 8);
      expect(sheet.duration(1, 0), 1 / 4);
    });

    test('rejects more rows than the grid holds', () async {
      final key = await solidAsset(4, 4);

      expect(
        () => SpriteSheet(key, .all(2), fps: 0, rows: [.new(), .new(), .new()]),
        throwsArgumentError,
      );
    });

    test('rejects a row that runs past the last column', () async {
      final key = await solidAsset(8, 2);

      expect(
        () => SpriteSheet(key, .all(2), fps: 0, rows: [.new(start: 2, frames: 3)]),
        throwsArgumentError,
      );
    });

    test('rejects a start column outside the sheet', () async {
      final key = await solidAsset(8, 2);

      expect(
        () => SpriteSheet(key, .all(2), fps: 0, rows: [.new(start: 4)]),
        throwsArgumentError,
      );
    });

    test('takes its rate from the row, falling back to the sheet', () async {
      final sheet = SpriteSheet(
        await solidAsset(4, 4),
        .all(2),
        fps: 10,
        rows: [
          .new(fps: 20),
        ],
      );

      expect(sheet.duration(0, 0), 1 / 20);
      expect(sheet.duration(1, 0), 1 / 10);
    });

    test('takes looping from the row, falling back to the sheet', () async {
      final sheet = SpriteSheet(
        await solidAsset(4, 4),
        .all(2),
        fps: 0,
        rows: [
          .new(loop: false),
        ],
      );

      expect(sheet.loops(0), isFalse);
      expect(sheet.loops(1), isTrue);
    });

    test('holds a frame forever without a rate', () async {
      final sheet = SpriteSheet(await solidAsset(4, 2), .all(2), fps: 0);

      expect(sheet.fps, 0);
      expect(sheet.duration(0, 0), double.infinity);
    });

    test('takes its frame count from its durations', () async {
      final sheet = SpriteSheet(
        await solidAsset(8, 2),
        .all(2),
        fps: 0,
        rows: [
          .timed([0.5, 0.25]),
        ],
      );

      expect(sheet.frames(0), 2);
    });

    test('holds each frame for its own duration', () async {
      final sheet = SpriteSheet(
        await solidAsset(8, 2),
        .all(2),
        fps: 60,
        rows: [
          .timed([0.5, 0.25, 0.125]),
        ],
      );

      expect(sheet.duration(0, 0), 0.5);
      expect(sheet.duration(0, 1), 0.25);
      expect(sheet.duration(0, 2), 0.125);
    });

    test('rejects an empty list of durations', () {
      expect(() => SheetRow.timed([]), throwsArgumentError);
    });

    test('rejects a duration that is not positive and finite', () {
      expect(() => SheetRow.timed([0.5, 0]), throwsArgumentError);
      expect(() => SheetRow.timed([0.5, double.infinity]), throwsArgumentError);
    });
  });

  group('reloading', () {
    test('re-cuts against a replaced image', () async {
      Ignis.cache.add('sheet.png', await solidImage(4, 2));
      final sheet = SpriteSheet('sheet.png', .all(2), fps: 0);

      expect(sheet.reload(), same(sheet));

      Ignis.cache.add('sheet.png', await solidImage(8, 2));
      final reloaded = sheet.reload();

      expect(reloaded, isNot(same(sheet)));
      expect(reloaded.columns, 4);
    });

    test('re-resolves an open-ended row against the new columns', () async {
      Ignis.cache.add('sheet.png', await solidImage(4, 2));

      final sheet = SpriteSheet(
        'sheet.png',
        .all(2),
        fps: 0,
        rows: [
          .new(start: 1),
        ],
      );

      expect(sheet.frames(0), 1);

      Ignis.cache.add('sheet.png', await solidImage(8, 2));

      expect(sheet.reload().frames(0), 3);
    });
  });

  group('keys', () {
    test('names the rows a sheet declares', () async {
      final sheet = SpriteSheet(
        await solidAsset(4, 4),
        .all(2),
        fps: 8,
        rows: [
          .new(key: 'idle'),
          .new(key: 'jump'),
        ],
      );

      expect(sheet.rowOf('idle'), 0);
      expect(sheet.rowOf('jump'), 1);
      expect(sheet.rowOf('spit'), isNull);
    });

    test('leaves an unnamed row unreachable by key', () async {
      final sheet = SpriteSheet(await solidAsset(4, 4), .all(2), fps: 8);

      expect(sheet.rowOf('idle'), isNull);
    });

    test('names the one row of a single-row sheet', () async {
      final sheet = SpriteSheet.single(
        await solidAsset(8, 2),
        .all(2),
        fps: 8,
        key: 'idle',
      );

      expect(sheet.rows, 1);
      expect(sheet.frames(0), 4);
      expect(sheet.rowOf('idle'), 0);
    });

    test('rejects a single-row sheet cut into more than one row', () async {
      final asset = await solidAsset(8, 4);

      expect(
        () => SpriteSheet.single(asset, .all(2), fps: 8, key: 'idle'),
        throwsArgumentError,
      );
    });

    test('names a whole image', () async {
      final sprite = SpriteImage(await solidAsset(8, 4), key: 'portrait');

      expect(sprite.rowOf('portrait'), 0);
      expect(sprite.rowOf('nothing'), isNull);
    });

    test('offsets the keys a group finds in its parts', () async {
      final group = SpriteGroup<String>([
        SpriteImage(await solidAsset(8, 4, RED), key: 'portrait'),
        SpriteSheet(
          await solidAsset(4, 4, BLUE),
          .all(2),
          fps: 8,
          rows: [
            .new(key: 'idle'),
            .new(key: 'jump'),
          ],
        ),
      ]);

      expect(group.rows, 3);
      expect(group.rowOf('portrait'), 0);
      expect(group.rowOf('idle'), 1);
      expect(group.rowOf('jump'), 2);
      expect(group.rowOf('nothing'), isNull);
    });

    test('keeps the keys of a group through a reload', () async {
      Ignis.cache.add('first.png', await solidImage(4, 2, RED));

      final group = SpriteGroup<String>([
        SpriteSheet.single('first.png', .all(2), fps: 8, key: 'first'),
        SpriteSheet.single(await solidAsset(4, 2, BLUE), .all(2), fps: 8, key: 'second'),
      ]);

      expect(group.reload(), same(group));

      Ignis.cache.add('first.png', await solidImage(8, 2, RED));
      final reloaded = group.reload();

      expect(reloaded, isNot(same(group)));
      expect(reloaded.frames(0), 4);
      expect(reloaded.rowOf('second'), 1);
    });
  });

  group('SpriteGroup', () {
    test('numbers rows straight through its parts', () async {
      final first = SpriteSheet(await solidAsset(4, 4, RED), .all(2), fps: 4);
      final second = SpriteSheet(await solidAsset(4, 4, BLUE), .all(2), fps: 8);
      final group = SpriteGroup([first, second]);

      expect(group.rows, 4);
      expect(group.image(1), same(first.image(1)));
      expect(group.image(3), same(second.image(1)));
      expect(group.rect(3, 1), second.rect(1, 1));
      expect(group.duration(0, 0), 1 / 4);
      expect(group.duration(3, 0), 1 / 8);
    });

    test('lets each part bring its own image and frame size', () async {
      final group = SpriteGroup([
        SpriteImage(await solidAsset(8, 4, RED)),
        SpriteSheet(await solidAsset(4, 4, BLUE), .all(2), fps: 0),
      ]);

      expect(group.rows, 3);
      expect(group.size(0), Vector2(8, 4));
      expect(group.size(1), Vector2.all(2));
      expect(group.frames(0), 1);
      expect(group.frames(1), 2);
    });

    test('rejects holding nothing', () {
      expect(() => SpriteGroup([]), throwsArgumentError);
    });

    test('re-resolves only the parts that changed', () async {
      Ignis.cache.add('first.png', await solidImage(4, 2, RED));
      final stable = SpriteSheet(await solidAsset(4, 2, BLUE), .all(2), fps: 0);
      final group = SpriteGroup([SpriteSheet('first.png', .all(2), fps: 0), stable]);

      expect(group.reload(), same(group));

      Ignis.cache.add('first.png', await solidImage(8, 2, RED));
      final reloaded = group.reload();

      expect(reloaded, isNot(same(group)));
      expect(reloaded.frames(0), 4);
      expect(reloaded.parts[1], same(stable));
    });
  });

  test('cuts the packed slime sheet into eleven ragged rows', () async {
    await Preload.run(loaders: [.image()], paths: ['test/assets/slime.png']);

    final sheet = SpriteSheet(
      'test/assets/slime.png',
      .all(56),
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
    );

    expect(sheet.rows, 11);
    expect(sheet.columns, 49);
    expect(
      [
        for (var row = 0; row < sheet.rows; row += 1) //
          sheet.frames(row),
      ],
      [14, 30, 25, 17, 30, 12, 13, 13, 45, 27, 49],
    );

    // The idle row stops at its own last frame, well short of the padding.
    expect(sheet.rect(0, 13), const Rect.fromLTWH(728, 0, 56, 56));
    expect(() => sheet.rect(0, 14), throwsRangeError);
  });
}
