import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

/// Watches a set of files and directories, reporting the files that change.
///
/// Knows nothing about Flutter, pubspecs, or asset manifests: hand it paths and
/// listen to [changes].
///
/// Directories are watched recursively, so a path nested inside another one in
/// the set is dropped. Watching both would deliver a single save twice, once
/// per overlapping watcher. Paths that do not exist are skipped.
///
/// Single-use by design. To watch a different set, [dispose] this one and build
/// another.
class AssetWatcher {
  AssetWatcher(Iterable<String> paths) : paths = Set.unmodifiable(paths);

  /// The paths this watcher was asked to cover.
  final Set<String> paths;

  final StreamController<String> _changes = .broadcast();

  /// The absolute path of each file that changes under [watching].
  Stream<String> get changes => _changes.stream;

  final List<StreamSubscription> _subscriptions = [];
  Set<String> _watching = const {};

  /// The subset of [paths] actually being watched.
  ///
  /// Smaller than [paths] when one path contains another, or when a path does
  /// not exist on disk.
  Set<String> get watching => _watching;

  /// Opens a watcher for each covered path, completing once they are all ready.
  Future<void> start() async {
    if (_subscriptions.isNotEmpty) {
      throw StateError('Already started.');
    }

    final watching = <String>{};
    final ready = <Future<void>>[];

    for (final path in _cover(paths)) {
      // Asking the filesystem is the only place a file is told from a
      // directory. A path may also not exist yet, which is not an error - a
      // project can declare an asset directory before creating it.
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

  /// The paths in [paths] that are not already inside another one.
  ///
  /// Needs no notion of what is a file and what is a directory: only a
  /// directory can contain another path, and a directory is watched
  /// recursively, so anything inside one is already reported.
  static Set<String> _cover(Set<String> paths) {
    return {
      for (final path in paths)
        if (!paths.any((other) => p.isWithin(other, path))) //
          path,
    };
  }

  // Every event a watcher emits names a file. Directories are tracked so they
  // can be descended into, never reported, so there is nothing to filter here.
  void _handle(WatchEvent event) => _changes.add(p.absolute(event.path));
}
