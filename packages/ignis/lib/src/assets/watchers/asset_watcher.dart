// SPDX-AI-Disclosure: ai-generated

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

/// Watches a set of files and directories, reporting the files that change.
///
/// Directories are watched recursively, so a path nested inside another one in
/// the set is dropped. Watching both would deliver a single save twice, once
/// per overlapping watcher. Paths that do not exist are skipped.
///
/// Single-use: to watch a different set, [dispose] this one and build another.
class AssetWatcher {
  AssetWatcher(Iterable<String> paths) : paths = Set.unmodifiable(paths);

  /// The paths this watcher was asked to cover.
  final Set<String> paths;

  final StreamController<String> _changes = .broadcast();

  /// The absolute path of each file that changes under [watching].
  Stream<String> get changes => _changes.stream;

  final List<StreamSubscription> _subscriptions = [];
  Set<String> _watching = const {};

  /// The subset of [paths] being watched: nested and missing paths are left out.
  Set<String> get watching => _watching;

  /// Opens a watcher for each covered path, completing once they are all ready.
  Future<void> start() async {
    if (_subscriptions.isNotEmpty) {
      throw StateError('Already started.');
    }

    final watching = <String>{};
    final ready = <Future<void>>[];

    for (final path in _cover(paths)) {
      // Only the filesystem tells a file from a directory. A missing path is
      // skipped: a project can declare an asset directory before creating it.
      final type = await FileSystemEntity.type(path);
      if (type == FileSystemEntityType.notFound) continue;

      final watcher = type == FileSystemEntityType.directory
          ? DirectoryWatcher(path) //
          : FileWatcher(path);

      _subscriptions.add(watcher.events.listen(_handle));
      ready.add(watcher.ready);
      watching.add(path);
    }

    _watching = Set.unmodifiable(watching);
    await Future.wait(ready);
  }

  Future<void> dispose() async {
    try {
      await Future.wait([
        for (final subscription in _subscriptions) //
          subscription.cancel(),
      ]);
    } finally {
      _subscriptions.clear();
      _watching = const {};
      await _changes.close();
    }
  }

  /// The paths in [paths] not inside another one. Directories are watched
  /// recursively, so anything inside one is already covered.
  static Set<String> _cover(Set<String> paths) {
    return {
      for (final path in paths)
        if (!paths.any((other) => p.isWithin(other, path))) //
          path,
    };
  }

  // Watcher events always name a file.
  void _handle(WatchEvent event) => _changes.add(p.absolute(event.path));
}
