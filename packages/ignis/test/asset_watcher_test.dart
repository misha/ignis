import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/src/assets/watchers/asset_watcher.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;

  String at(List<String> parts) => p.joinAll([root.path, ...parts]);

  Future<void> write(List<String> parts, String contents) async {
    final file = File(at(parts));
    await file.parent.create(recursive: true);
    await file.writeAsString(contents, flush: true);
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
    root = await Directory.systemTemp.createTemp('ignis-watcher');
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  test('reports a file changing inside a watched directory', () async {
    await write(['art', 'hero.txt'], 'red');

    final watcher = AssetWatcher([
      at(['art']),
    ]);
    final changes = <String>[];
    watcher.changes.listen(changes.add);
    await watcher.start();

    await write(['art', 'hero.txt'], 'blue');

    await eventually(
      () => changes.any((path) => p.equals(path, at(['art', 'hero.txt']))),
      'the change was never reported',
    );

    await watcher.dispose();
  });

  test('watches a bare file on its own', () async {
    await write(['notes.txt'], 'one');

    final watcher = AssetWatcher([
      at(['notes.txt']),
    ]);
    final changes = <String>[];
    watcher.changes.listen(changes.add);
    await watcher.start();

    expect(watcher.watching, {
      at(['notes.txt']),
    });

    await write(['notes.txt'], 'two');

    await eventually(
      () => changes.isNotEmpty,
      'the file change was never reported',
    );

    await watcher.dispose();
  });

  test('drops a path already inside another', () async {
    await write(['art', 'nested', 'hero.txt'], 'red');
    await write(['art', 'logo.txt'], 'logo');

    final watcher = AssetWatcher([
      at(['art']),
      at(['art', 'nested']),
      at(['art', 'logo.txt']),
    ]);

    await watcher.start();

    // Watching all three would report one save up to three times.
    expect(watcher.watching, {
      at(['art']),
    });

    await watcher.dispose();
  });

  test('keeps paths that do not contain each other', () async {
    await write(['art', 'hero.txt'], 'red');
    await write(['sound', 'boom.txt'], 'boom');

    final watcher = AssetWatcher([
      at(['art']),
      at(['sound']),
    ]);
    await watcher.start();

    expect(watcher.watching, {
      at(['art']),
      at(['sound']),
    });

    await watcher.dispose();
  });

  test('skips a path that does not exist', () async {
    await write(['art', 'hero.txt'], 'red');

    final watcher = AssetWatcher([
      at(['art']),
      at(['missing']),
    ]);
    await watcher.start();

    expect(watcher.paths, hasLength(2));
    expect(watcher.watching, {
      at(['art']),
    });

    await watcher.dispose();
  });

  test('rejects starting twice', () async {
    await write(['art', 'hero.txt'], 'red');

    final watcher = AssetWatcher([
      at(['art']),
    ]);
    await watcher.start();

    expect(watcher.start, throwsStateError);

    await watcher.dispose();
  });
}
