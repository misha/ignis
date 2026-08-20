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

  group('SpriteRegion', () {
    test('measures a grid over the image it names', () async {
      final region = SpriteRegion(await solidAsset(8, 6), .all(2), row: 1);

      expect(region.columns, 4);
      expect(region.rows, 3);
      expect(region.frames, 4);
      expect(region.cut(), const [
        Rect.fromLTWH(0, 2, 2, 2),
        Rect.fromLTWH(2, 2, 2, 2),
        Rect.fromLTWH(4, 2, 2, 2),
        Rect.fromLTWH(6, 2, 2, 2),
      ]);
    });

    test('cuts the span it is given', () async {
      final region = SpriteRegion(
        await solidAsset(8, 2),
        .all(2),
        start: 1,
        end: 3,
      );

      expect(region.frames, 2);
      expect(region.cut(), const [
        Rect.fromLTWH(2, 0, 2, 2),
        Rect.fromLTWH(4, 0, 2, 2),
      ]);
    });

    test('re-reads the width of a replacement while left open', () async {
      Ignis.cache.add('sheet.png', await solidImage(4, 2));
      final region = SpriteRegion('sheet.png', .all(2), start: 1);

      expect(region.frames, 1);

      Ignis.cache.add('sheet.png', await solidImage(8, 2));

      expect(region.frames, 3);
      expect(region.fits, isTrue);
    });

    test('holds its span through a replacement while stated', () async {
      Ignis.cache.add('sheet.png', await solidImage(8, 2));
      final region = SpriteRegion('sheet.png', .all(2), end: 2);

      Ignis.cache.add('sheet.png', await solidImage(16, 2));

      expect(region.frames, 2);
    });

    test('stops fitting art it no longer sits inside', () async {
      Ignis.cache.add('sheet.png', await solidImage(4, 4));
      final region = SpriteRegion('sheet.png', .all(2), row: 1);

      expect(region.fits, isTrue);

      Ignis.cache.add('sheet.png', await solidImage(4, 2));

      expect(region.fits, isFalse);
    });

    test('covers the whole of an image', () async {
      final region = SpriteRegion.whole(await solidAsset(8, 4));

      expect(region.frames, 1);
      expect(region.cell, Vector2(8, 4));
      expect(region.cut(), const [Rect.fromLTWH(0, 0, 8, 4)]);
    });

    test('requires positive finite frame dimensions', () async {
      final key = await solidAsset(4, 4);

      expect(() => SpriteRegion(key, .new(0, 2)), throwsArgumentError);
      expect(
        () => SpriteRegion(key, .new(2, double.infinity)),
        throwsArgumentError,
      );
    });

    test('requires frame dimensions to divide the image evenly', () async {
      final key = await solidAsset(4, 4);

      expect(() => SpriteRegion(key, .new(3, 2)), throwsArgumentError);
      expect(() => SpriteRegion(key, .new(2, 3)), throwsArgumentError);
    });

    test('rejects a row outside the image', () async {
      final key = await solidAsset(4, 4);

      expect(() => SpriteRegion(key, .all(2), row: 2), throwsArgumentError);
      expect(() => SpriteRegion(key, .all(2), row: -1), throwsArgumentError);
    });

    test('rejects a span outside the columns', () async {
      final key = await solidAsset(8, 2);

      expect(() => SpriteRegion(key, .all(2), start: 4), throwsArgumentError);
      expect(
        () => SpriteRegion(key, .all(2), start: 2, end: 5),
        throwsArgumentError,
      );
      expect(
        () => SpriteRegion(key, .all(2), start: 2, end: 2),
        throwsArgumentError,
      );
    });
  });

  group('SpriteImage', () {
    test('draws the whole image as one frame', () async {
      final image = await solidImage(8, 4);
      Ignis.cache.add('hero.png', image);
      final sprite = SpriteImage('hero.png');
      final entry = sprite.entries.single;

      expect(sprite.asset, 'hero.png');
      expect(sprite.reload(), same(sprite));
      expect(entry.image, same(image));
      expect(entry.size, Vector2(8, 4));
      expect(entry.frames, 1);
      expect(entry.rect(0), const Rect.fromLTWH(0, 0, 8, 4));
      expect(entry.duration(0), double.infinity);
      expect(entry.loops, isFalse);
    });

    test('re-measures against a replaced image', () async {
      Ignis.cache.add('hero.png', await solidImage(8, 4));
      final sprite = SpriteImage('hero.png');
      final replacement = await solidImage(16, 8);
      Ignis.cache.add('hero.png', replacement);

      final reloaded = sprite.reload();
      final entry = reloaded.entries.single;

      expect(reloaded, isNot(same(sprite)));
      expect(entry.image, same(replacement));
      expect(entry.size, Vector2(16, 8));
    });

    test('answers only for the entry it holds', () async {
      final sprite = SpriteImage(await solidAsset(8, 4));

      expect(sprite.resolve(0)?.index, 0);
      expect(sprite.resolve(1), isNull);
    });
  });

  group('SpriteAnimation', () {
    test('plays every column of the file it is given', () async {
      final animation = SpriteAnimation(
        await solidAsset(8, 2),
        .all(2),
        fps: 8,
      );

      final entry = animation.entries.single;

      expect(entry.frames, 4);
      expect(entry.rect(0), const Rect.fromLTWH(0, 0, 2, 2));
      expect(entry.rect(3), const Rect.fromLTWH(6, 0, 2, 2));
      expect(entry.duration(0), 1 / 8);
      expect(entry.loops, isTrue);
      expect(() => entry.rect(4), throwsRangeError);
    });

    test('plays the span it is given', () async {
      final entry = SpriteAnimation(
        await solidAsset(8, 2),
        .all(2),
        start: 1,
        end: 3,
        fps: 0,
      ).entries.single;

      expect(entry.frames, 2);
      expect(entry.rect(1), const Rect.fromLTWH(4, 0, 2, 2));
    });

    test('holds a frame forever without a rate', () async {
      final animation = SpriteAnimation(await solidAsset(4, 2), .all(2), fps: 0);

      expect(animation.entries.single.duration(0), double.infinity);
    });

    test('takes the looping it is given', () async {
      final animation = SpriteAnimation(
        await solidAsset(4, 2),
        .all(2),
        fps: 8,
        loop: false,
      );

      expect(animation.entries.single.loops, isFalse);
    });

    test('holds each frame for its own duration', () async {
      final entry = SpriteAnimation.timed(
        await solidAsset(8, 2),
        .all(2),
        [0.5, 0.25, 0.125],
      ).entries.single;

      expect(entry.frames, 3);
      expect(entry.duration(0), 0.5);
      expect(entry.duration(1), 0.25);
      expect(entry.duration(2), 0.125);
    });

    test('takes the row it names out of a grid', () async {
      final entry = SpriteAnimation(
        await solidAsset(4, 6),
        .all(2),
        row: 2,
        fps: 0,
      ).entries.single;

      expect(entry.rect(0), const Rect.fromLTWH(0, 4, 2, 2));
    });

    test('rejects a file it cuts into more than one row', () async {
      final key = await solidAsset(4, 4);

      expect(() => SpriteAnimation(key, .all(2), fps: 8), throwsArgumentError);
      expect(
        () => SpriteAnimation.timed(key, .all(2), [0.5]),
        throwsArgumentError,
      );
    });

    test('rejects a rate that is not finite and positive', () async {
      final key = await solidAsset(4, 2);

      expect(() => SpriteAnimation(key, .all(2), fps: -1), throwsArgumentError);
      expect(
        () => SpriteAnimation(key, .all(2), fps: double.infinity),
        throwsArgumentError,
      );
    });

    test('rejects an empty list of durations', () async {
      final key = await solidAsset(4, 2);

      expect(() => SpriteAnimation.timed(key, .all(2), []), throwsArgumentError);
    });

    test('rejects a duration that is not positive and finite', () async {
      final key = await solidAsset(8, 2);

      expect(
        () => SpriteAnimation.timed(key, .all(2), [0.5, 0]),
        throwsArgumentError,
      );
      expect(
        () => SpriteAnimation.timed(key, .all(2), [0.5, double.infinity]),
        throwsArgumentError,
      );
    });

    test('answers only for the entry it holds', () async {
      final animation = SpriteAnimation(await solidAsset(4, 2), .all(2), fps: 0);

      expect(animation.resolve(0)?.index, 0);
      expect(animation.resolve(1), isNull);
    });
  });

  group('SpriteSheet', () {
    test('measures the grid over its image', () async {
      Ignis.cache.add('sheet.png', await solidImage(8, 6));
      final sheet = SpriteSheet('sheet.png', .all(2));

      expect(sheet.asset, 'sheet.png');
      expect(sheet.columns, 4);
      expect(sheet.rows, 3);
    });

    test('copies the supplied frame size', () async {
      final size = MVector2.all(2);
      final sheet = SpriteSheet(await solidAsset(4, 4), size);

      size.splat(1);

      expect(sheet.cell, Vector2.all(2));
    });

    test('takes one frame of the grid as a still image', () async {
      final sheet = SpriteSheet(await solidAsset(8, 4), .all(2));
      final entry = sheet.image(row: 1, column: 3).entries.single;

      expect(entry.frames, 1);
      expect(entry.rect(0), const Rect.fromLTWH(6, 2, 2, 2));
      expect(entry.duration(0), double.infinity);
    });

    test('takes one row of the grid as an animation', () async {
      final sheet = SpriteSheet(await solidAsset(8, 4), .all(2));
      final entry = sheet.animation(row: 1, end: 3, fps: 8).entries.single;

      expect(entry.frames, 3);
      expect(entry.rect(0), const Rect.fromLTWH(0, 2, 2, 2));
      expect(entry.duration(0), 1 / 8);
    });

    test('takes one row of the grid with its own frame timings', () async {
      final sheet = SpriteSheet(await solidAsset(8, 4), .all(2));
      final entry = sheet.timed([0.5, 0.25], row: 1).entries.single;

      expect(entry.frames, 2);
      expect(entry.duration(0), 0.5);
    });

    test('takes one row of the grid as many times as it is asked', () async {
      final sheet = SpriteSheet(await solidAsset(4, 4), .all(2));
      final walk = sheet.animation(row: 1, fps: 10).entries.single;
      final slow = sheet.animation(row: 1, fps: 5).entries.single;

      expect(walk.rect(0), slow.rect(0));
      expect(walk.duration(0), 1 / 10);
      expect(slow.duration(0), 1 / 5);
    });

    test('takes every row of the grid as one run', () async {
      final sheet = SpriteSheet(await solidAsset(4, 6), .all(2));
      final run = sheet.animations(fps: 4);

      expect(run.entries.length, 3);
      expect(run.entries[0].rect(0), const Rect.fromLTWH(0, 0, 2, 2));
      expect(run.entries[2].rect(0), const Rect.fromLTWH(0, 4, 2, 2));
      expect(run.entries[1].duration(0), 1 / 4);
    });
  });

  group('SheetRow', () {
    test('stops each row where it says', () async {
      final sheet = SpriteSheet(await solidAsset(8, 6), .all(2));

      final run = sheet.animations(
        fps: 4,
        rows: [
          .new(end: 2),
          .new(end: 3),
        ],
      );

      expect(run.entries.length, 3);
      expect(run.entries[0].frames, 2);
      expect(run.entries[1].frames, 3);
      expect(run.entries[2].frames, 4);
    });

    test('plays every column after its start', () async {
      final sheet = SpriteSheet(await solidAsset(8, 2), .all(2));

      final run = sheet.animations(
        fps: 0,
        rows: [
          .new(start: 1),
        ],
      );

      final entry = run.entries.single;

      expect(entry.frames, 3);
      expect(entry.rect(0), const Rect.fromLTWH(2, 0, 2, 2));
    });

    test('states its own rate and looping', () async {
      final sheet = SpriteSheet(await solidAsset(4, 4), .all(2));

      final run = sheet.animations(
        fps: 10,
        rows: [
          .new(fps: 20, loop: false),
        ],
      );

      expect(run.entries[0].duration(0), 1 / 20);
      expect(run.entries[0].loops, isFalse);
      expect(run.entries[1].duration(0), 1 / 10);
      expect(run.entries[1].loops, isTrue);
    });

    test('holds each frame for its own duration', () async {
      final sheet = SpriteSheet(await solidAsset(8, 2), .all(2));

      final run = sheet.animations(
        fps: 60,
        rows: [
          .timed([0.5, 0.25, 0.125]),
        ],
      );

      final entry = run.entries.single;

      expect(entry.frames, 3);
      expect(entry.duration(0), 0.5);
      expect(entry.duration(2), 0.125);
    });

    test('passes over a row it skips, keeping the rest in place', () async {
      final sheet = SpriteSheet(await solidAsset(4, 6), .all(2));

      final run = sheet.animations(
        fps: 0,
        rows: [
          .skip(1),
          .new(),
          .skip(1),
        ],
      );

      expect(run.entries.length, 1);
      expect(run.entries[0].rect(0), const Rect.fromLTWH(0, 2, 2, 2));
    });

    test('passes over as many rows as a skip counts', () async {
      final sheet = SpriteSheet(await solidAsset(4, 8), .all(2));

      final run = sheet.animations(
        fps: 0,
        rows: [
          .skip(3),
          .new(),
        ],
      );

      expect(run.entries.length, 1);
      expect(run.entries[0].rect(0), const Rect.fromLTWH(0, 6, 2, 2));
    });

    test('keeps the rows after a skip on their own art', () async {
      final sheet = SpriteSheet(await solidAsset(4, 8), .all(2));

      final run = sheet.animations(
        fps: 0,
        rows: [
          .new(),
          .skip(1),
          .new(),
          .new(),
        ],
      );

      expect(run.entries.length, 3);
      expect(run.entries[0].rect(0), const Rect.fromLTWH(0, 0, 2, 2));
      expect(run.entries[1].rect(0), const Rect.fromLTWH(0, 4, 2, 2));
      expect(run.entries[2].rect(0), const Rect.fromLTWH(0, 6, 2, 2));
    });

    test('rejects a skip that runs past the last row', () async {
      final sheet = SpriteSheet(await solidAsset(4, 4), .all(2));

      expect(
        () => sheet.animations(fps: 0, rows: [.skip(3)]),
        throwsArgumentError,
      );
    });

    test('rejects more rows than the grid holds', () async {
      final sheet = SpriteSheet(await solidAsset(4, 4), .all(2));

      expect(
        () => sheet.animations(fps: 0, rows: [.new(), .new(), .new()]),
        throwsArgumentError,
      );
    });

    test('rejects a row that stops past the last column', () async {
      final sheet = SpriteSheet(await solidAsset(4, 4), .all(2));

      expect(
        () => sheet.animations(fps: 0, rows: [.new(end: 3)]),
        throwsArgumentError,
      );
    });

    test('rejects skipping every row it holds', () async {
      final sheet = SpriteSheet(await solidAsset(4, 4), .all(2));

      expect(
        () => sheet.animations(fps: 0, rows: [.skip(2)]),
        throwsArgumentError,
      );
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
    test('re-cuts an open animation against a replaced image', () async {
      Ignis.cache.add('sheet.png', await solidImage(4, 2));
      final animation = SpriteAnimation('sheet.png', .all(2), fps: 0);

      expect(animation.reload(), same(animation));

      Ignis.cache.add('sheet.png', await solidImage(8, 2));
      final reloaded = animation.reload();

      expect(reloaded, isNot(same(animation)));
      expect(reloaded.entries.single.frames, 4);
    });

    test('holds an animation that states its end through a reload', () async {
      Ignis.cache.add('sheet.png', await solidImage(4, 2));
      final animation = SpriteAnimation('sheet.png', .all(2), end: 1, fps: 0);

      Ignis.cache.add('sheet.png', await solidImage(8, 2));

      expect(animation.reload().entries.single.frames, 1);
    });

    test('holds art it no longer sits inside', () async {
      Ignis.cache.add('sheet.png', await solidImage(4, 4));
      final sheet = SpriteSheet('sheet.png', .all(2));
      final held = sheet.animation(row: 1, fps: 0);

      Ignis.cache.add('sheet.png', await solidImage(4, 2));

      expect(held.reload(), same(held));
    });
  });

  group('SpriteMap', () {
    test('names what it holds', () async {
      final sheet = SpriteSheet(await solidAsset(4, 4), .all(2));

      final map = SpriteMap({
        'idle': sheet.animation(row: 0, fps: 8),
        'jump': sheet.animation(row: 1, fps: 8),
      });

      expect(map.entries.length, 2);
      expect(map.resolve('idle')?.index, 0);
      expect(map.resolve('jump')?.index, 1);
      expect(map.resolve('spit'), isNull);
    });

    test('numbers entries in the order it states them', () async {
      final sheet = SpriteSheet(await solidAsset(4, 4, BLUE), .all(2));

      final map = SpriteMap({
        'portrait': SpriteImage(await solidAsset(8, 4, RED)),
        'idle': sheet.animation(row: 0, fps: 8),
        'jump': sheet.animation(row: 1, fps: 8),
      });

      expect(map.entries.length, 3);
      expect(map.resolve('portrait')?.index, 0);
      expect(map.resolve('idle')?.index, 1);
      expect(map.resolve('jump')?.index, 2);
      expect(map.entries[0].size, Vector2(8, 4));
      expect(map.entries[1].size, Vector2.all(2));
    });

    test('rejects a name holding more than one entry', () async {
      final run =
          SpriteSheet(await solidAsset(4, 4, BLUE), .all(2)) //
              .animations(fps: 8);

      expect(() => SpriteMap({'slime': run}), throwsArgumentError);
    });

    test('rejects holding nothing', () {
      expect(() => SpriteMap<String>({}), throwsArgumentError);
    });

    test('keeps its names through a reload', () async {
      Ignis.cache.add('first.png', await solidImage(4, 2, RED));

      final map = SpriteMap({
        'first': SpriteAnimation('first.png', .all(2), fps: 8),
        'second': SpriteAnimation(await solidAsset(4, 2, BLUE), .all(2), fps: 8),
      });

      expect(map.reload(), same(map));

      Ignis.cache.add('first.png', await solidImage(8, 2, RED));
      final reloaded = map.reload();

      expect(reloaded, isNot(same(map)));
      expect(reloaded.entries[0].frames, 4);
      expect(reloaded.resolve('second')?.index, 1);
    });
  });

  group('SpriteGroup', () {
    test('numbers entries straight through its parts', () async {
      final first =
          SpriteSheet(await solidAsset(4, 4, RED), .all(2)) //
              .animations(fps: 4);
      final second =
          SpriteSheet(await solidAsset(4, 4, BLUE), .all(2)) //
              .animations(fps: 8);
      final group = SpriteGroup([first, second]);

      expect(group.entries.length, 4);
      expect(group.entries[1].image, same(first.entries[1].image));
      expect(group.entries[3].image, same(second.entries[1].image));
      expect(group.entries[3].rect(1), second.entries[1].rect(1));
      expect(group.entries[0].duration(0), 1 / 4);
      expect(group.entries[3].duration(0), 1 / 8);
    });

    test('lets each part bring its own image and frame size', () async {
      final group = SpriteGroup([
        SpriteImage(await solidAsset(8, 4, RED)),
        SpriteAnimation(await solidAsset(4, 2, BLUE), .all(2), fps: 0),
      ]);

      final first = group.entries[0];
      final second = group.entries[1];

      expect(group.entries.length, 2);
      expect(first.size, Vector2(8, 4));
      expect(first.frames, 1);
      expect(second.size, Vector2.all(2));
      expect(second.frames, 2);
    });

    test('rejects holding nothing', () {
      expect(() => SpriteGroup([]), throwsArgumentError);
    });

    test('re-resolves only the parts that changed', () async {
      Ignis.cache.add('first.png', await solidImage(4, 2, RED));

      final stable = SpriteAnimation(
        await solidAsset(4, 2, BLUE),
        .all(2),
        fps: 0,
      );

      final group = SpriteGroup([
        SpriteAnimation('first.png', .all(2), fps: 0),
        stable,
      ]);

      expect(group.reload(), same(group));

      Ignis.cache.add('first.png', await solidImage(8, 2, RED));
      final reloaded = group.reload();

      expect(reloaded, isNot(same(group)));
      expect(reloaded.entries[0].frames, 4);
      expect(reloaded.parts[1], same(stable));
    });
  });

  test('cuts the packed slime sheet into eleven ragged rows', () async {
    await Preload.run(loaders: [.image()], paths: ['test/assets/slime.png']);

    final sheet = SpriteSheet('test/assets/slime.png', .all(56));

    final run = sheet.animations(
      fps: 16,
      rows: [
        .new(end: 14),
        .new(end: 30),
        .new(end: 25),
        .new(end: 17),
        .new(end: 30),
        .new(end: 12),
        .new(end: 13),
        .new(end: 13),
        .new(end: 45),
        .new(end: 27),
        .new(end: 49),
      ],
    );

    expect(sheet.columns, 49);
    expect(sheet.rows, 11);
    expect(run.entries.length, 11);
    expect(
      [
        for (final entry in run.entries) //
          entry.frames,
      ],
      [14, 30, 25, 17, 30, 12, 13, 13, 45, 27, 49],
    );

    // The idle row stops at its own last frame, well short of the padding.
    expect(run.entries[0].rect(13), const Rect.fromLTWH(728, 0, 56, 56));
    expect(() => run.entries[0].rect(14), throwsRangeError);
  });
}
