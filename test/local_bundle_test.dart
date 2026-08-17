import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';
import 'package:path/path.dart' as p;

import 'support/colors.dart';
import 'support/images.dart';
import 'support/test_bundle.dart';

/// End-to-end coverage for local asset reloading.
///
/// Each test builds a throwaway Flutter project in a temp directory: a pubspec
/// with nothing but an assets manifest, and an `assets/` directory the test
/// writes real PNGs into. A [LocalAssetBundle] is pointed at it, so a write to
/// disk drives the whole chain, exactly as it would in a running game.
///
///   write assets/hero.png
///     -> PubspecWatcher matches it against the pubspec manifest
///     -> LocalAssetBundle reads the new bytes off disk
///     -> Preload runs them through the image loader
///     -> Cache.add replaces the image
///     -> SpriteSheet.reload() re-cuts, when the tree is reassembled
///
/// Nothing here waits a fixed duration. Filesystem events have no guaranteed
/// latency, so the tests wait on the outcome instead; the timeout is only ever
/// reached when something is actually broken.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late LocalAssetBundle local;
  late AssetBundle bundle;

  /// Writes [image] to [parts] joined under the project root.
  Future<void> write(List<String> parts, Image image) async {
    final data = await image.toByteData(format: .png);
    final file = File(p.joinAll([root.path, ...parts]));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List(), flush: true);
  }

  /// The image cached at [key], or null when there is none.
  Image? cached(String key) {
    if (!Ignis.cache.contains(key)) return null;
    return Ignis.cache.retrieve<Image>(key);
  }

  /// Waits until [condition] holds, failing the test if it never does.
  Future<void> eventually(bool Function() condition, String reason) async {
    final deadline = DateTime.now().add(const Duration(seconds: 1));

    while (!condition()) {
      if (DateTime.now().isAfter(deadline)) fail(reason);
      await Future.delayed(const Duration(milliseconds: 5));
    }
  }

  setUp(() async {
    bundle = Ignis.bundle;
    Ignis.cache.clear();

    root = await Directory.systemTemp.createTemp('ignis-live');

    // Only `assets/` is declared, and Flutter globs it exactly one level deep.
    await File(p.join(root.path, 'pubspec.yaml')).writeAsString('''
name: game
flutter:
  assets:
    - assets/
''');

    // Two 1x1 frames, red.
    await write(['assets', 'hero.png'], await solidImage(2, 1, RED));

    local = LocalAssetBundle(root: root.path, delegate: TestBundle());
    Ignis.bundle = local;
    Ignis.preload = Preload()..register(.image()..extensions(['.png']));
  });

  tearDown(() async {
    await local.dispose();
    await Ignis.preload.dispose();
    await root.delete(recursive: true);
    Ignis.bundle = bundle;
    Ignis.cache.clear();
  });

  /// Preloads the starting [paths] and begins watching.
  ///
  /// Loaded by name rather than by manifest: `AssetManifest.bin` is compiled at
  /// build time, so a project synthesized inside a test has none. That is the
  /// same reason live reloading reads assets off disk in the first place.
  Future<void> start([List<String> paths = const ['assets/hero.png']]) async {
    final request = Ignis.preload.load(paths: paths);
    await request;
    request.dispose();
    expect(await local.start(), isTrue, reason: 'the watcher failed to start');
  }

  test('serves an asset off disk rather than the compiled bundle', () async {
    await start();

    final image = cached('assets/hero.png');
    expect(image, isNotNull);
    expect(image!.width, 2);
    expect(await pixelAt(image, 0, 0), RED);
  });

  test('falls through to the delegate bundle for anything not under the root', () async {
    // Lives in this package's own assets, not the temp project.
    final data = await local.load('test/assets/fire.png');
    expect(data.lengthInBytes, greaterThan(0));
  });

  test('reloads a changed asset into the cache', () async {
    await start();
    final original = cached('assets/hero.png')!;

    await write(['assets', 'hero.png'], await solidImage(4, 1, BLUE));

    await eventually(
      () => !identical(cached('assets/hero.png'), original),
      'the changed asset never reached the cache',
    );

    final replaced = cached('assets/hero.png')!;
    expect(replaced.width, 4, reason: 'the bytes did not come off disk');
    expect(await pixelAt(replaced, 0, 0), BLUE);
  });

  test('re-cuts a sheet from a changed image', () async {
    await start();

    final sheet = SpriteSheet('assets/hero.png', .all(1), fps: 0);
    expect(sheet.frames(0), 2);

    await write(['assets', 'hero.png'], await solidImage(4, 1, BLUE));

    await eventually(
      () => cached('assets/hero.png')!.width == 4,
      'the changed asset never reached the cache',
    );

    final reloaded = sheet.reload();
    expect(reloaded, isNot(same(sheet)));
    expect(reloaded.frames(0), 4);
    expect(reloaded.image(0), same(cached('assets/hero.png')));
  });

  test('carries a live change into a SpriteNode when it is reassembled', () async {
    await start();

    final node = SpriteNode(sprite: SpriteSheet('assets/hero.png', .all(1), fps: 0));
    expect(node.sprite.frames(0), 2);

    await write(['assets', 'hero.png'], await solidImage(4, 1, BLUE));

    await eventually(
      () => cached('assets/hero.png')!.width == 4,
      'the changed asset never reached the cache',
    );

    node.reassemble();

    expect(node.sprite.frames(0), 4, reason: 'the node did not re-read the cache');
    expect(node.sprite.image(0), same(cached('assets/hero.png')));
  });

  test('clamps a sprite frame the reloaded sheet no longer has', () async {
    // Four frames to begin with, so frame 3 is valid.
    await write(['assets', 'hero.png'], await solidImage(4, 1, RED));
    await start();

    final node = SpriteNode(sprite: SpriteSheet('assets/hero.png', .all(1), fps: 0));
    node.play(frame: 3);
    expect(node.frame, 3);

    // Down to two frames, leaving frame 3 out of range.
    await write(['assets', 'hero.png'], await solidImage(2, 1, BLUE));

    await eventually(
      () => cached('assets/hero.png')!.width == 2,
      'the changed asset never reached the cache',
    );

    node.reassemble();

    expect(node.sprite.frames(0), 2);
    expect(node.frame, 0, reason: 'the stale frame index was not clamped');
  });

  test('ignores a change outside the pubspec manifest', () async {
    await start();
    final original = cached('assets/hero.png')!;

    // `assets/` globs one level deep, so a nested directory is not covered.
    await write(['assets', 'nested', 'deep.png'], await solidImage(2, 1, BLUE));

    // A watched asset written afterwards is the control: once its reload has
    // landed, the ignored event has had its chance too.
    await write(['assets', 'hero.png'], await solidImage(4, 1, BLUE));

    await eventually(
      () => !identical(cached('assets/hero.png'), original),
      'the control asset never reloaded',
    );

    expect(Ignis.cache.contains('assets/nested/deep.png'), isFalse);
  });

  test('ignores a change the loaders reject', () async {
    await start();
    final original = cached('assets/hero.png')!;

    // Watched, but the image loader only accepts `.png`.
    await File(p.join(root.path, 'assets', 'notes.txt')).writeAsString('hello');
    await write(['assets', 'hero.png'], await solidImage(4, 1, BLUE));

    await eventually(
      () => !identical(cached('assets/hero.png'), original),
      'the control asset never reloaded',
    );

    expect(Ignis.cache.contains('assets/notes.txt'), isFalse);
  });

  test('caches nothing when no loader is registered on the global preload', () async {
    // The trap: loaders registered on some other Preload instance leave
    // Ignis.preload empty, and live reloading only ever goes through that one.
    await start();
    Ignis.preload = Preload();

    await write(['assets', 'hero.png'], await solidImage(4, 1, BLUE));

    final request = Ignis.preload.load(paths: ['assets/hero.png']);
    await request;

    expect(request.completed, 1);
    expect(request.accepted, 0, reason: 'a bare preload cannot load anything');
    request.dispose();
  });

  test('reports how many assets its loaders actually accepted', () async {
    await start();

    // Watched and readable, but the image loader only accepts `.png`.
    await File(p.join(root.path, 'assets', 'notes.txt')).writeAsString('hello');

    final request = Ignis.preload.load(
      paths: ['assets/hero.png', 'assets/notes.txt'],
    );

    await request;

    expect(request.completed, 2);
    expect(request.accepted, 1);
    request.dispose();
  });

  test('watches every asset root the manifest declares', () async {
    await File(p.join(root.path, 'pubspec.yaml')).writeAsString('''
name: game
flutter:
  assets:
    - assets/
    - art/exported/
''');

    await write(['art', 'exported', 'villain.png'], await solidImage(2, 1, RED));
    await start(['assets/hero.png', 'art/exported/villain.png']);

    final original = cached('art/exported/villain.png')!;
    await write(['art', 'exported', 'villain.png'], await solidImage(4, 1, BLUE));

    await eventually(
      () => !identical(cached('art/exported/villain.png'), original),
      'the second asset root was never watched',
    );

    expect(cached('art/exported/villain.png')!.width, 4);
  });

  test('re-targets its watchers when the manifest changes', () async {
    await start();

    // A directory the manifest does not mention yet.
    await write(['art', 'villain.png'], await solidImage(2, 1, RED));

    await File(p.join(root.path, 'pubspec.yaml')).writeAsString('''
name: game
flutter:
  assets:
    - assets/
    - art/
''');

    await eventually(
      () => local.watching.contains('art'),
      'the watcher never picked up the new manifest entry',
    );

    await write(['art', 'villain.png'], await solidImage(4, 1, BLUE));

    await eventually(
      () => Ignis.cache.contains('art/villain.png'),
      'the newly declared directory was never watched',
    );
  });

  test('picks up an asset that did not exist at startup', () async {
    await start();

    await write(['assets', 'villain.png'], await solidImage(2, 1, BLUE));

    await eventually(
      () => Ignis.cache.contains('assets/villain.png'),
      'a newly created asset never reached the cache',
    );

    expect(cached('assets/villain.png')!.width, 2);
  });
}
