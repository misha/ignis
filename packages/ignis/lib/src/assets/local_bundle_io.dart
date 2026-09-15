// SPDX-AI-Disclosure: ai-generated

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ignis/src/assets/watchers/pubspec_watcher.dart';
import 'package:ignis/src/globals.dart';
import 'package:path/path.dart' as p;

/// Serves assets straight off the developer's disk, and pushes changes back
/// through [Ignis.preload] so the cache follows along.
///
/// Local: the app and the project source must share a filesystem.
///
/// Install it over [Ignis.bundle], then [start] it:
///
/// ```dart
/// final local = LocalAssetBundle();
/// Ignis.bundle = local;
/// await local.start();
/// ```
///
/// Outside [kDebugMode], this is inert: [start] does nothing and every load
/// delegates to [delegate], so it is safe to install unconditionally.
class LocalAssetBundle extends CachingAssetBundle {
  /// The project directory asset keys are resolved against.
  final String root;

  /// Where a key that is not a file under [root] is loaded from.
  final AssetBundle delegate;

  final PubspecWatcher _watcher;

  StreamSubscription<String>? _updates;

  /// Whether live reloading is currently active.
  bool get isRunning => _watcher.isRunning;

  /// The manifest entries currently being watched, relative to [root].
  ///
  /// Derived from the project's `pubspec.yaml`.
  Iterable<String> get watching => _watcher.watching;

  /// Creates a local bundle rooted at [root], defaulting to the working
  /// directory of the running process.
  factory LocalAssetBundle({
    String? root,
    AssetBundle? delegate,
  }) {
    final directory = root ?? Directory.current.path;

    return LocalAssetBundle._(
      directory,
      delegate ?? rootBundle,
      .new(pubspecPath: p.join(directory, 'pubspec.yaml')),
    );
  }

  LocalAssetBundle._(this.root, this.delegate, this._watcher);

  /// Starts watching for asset changes, returning whether it succeeded.
  ///
  /// Always false outside [kDebugMode].
  Future<bool> start() async {
    if (!kDebugMode) return false;
    _updates ??= _watcher.updates.listen(_update);
    return _watcher.start();
  }

  /// Stops watching for asset changes.
  Future<void> stop() async {
    try {
      await Future.wait([
        ?_updates?.cancel(),
        _watcher.stop(),
      ]);
    } finally {
      _updates = null;
    }
  }

  Future<void> dispose() async {
    await stop();
    await _watcher.dispose();
  }

  @override
  Future<ByteData> load(String key) async {
    if (kDebugMode) {
      final file = File(p.join(root, key));

      if (await file.exists()) {
        return .sublistView(await file.readAsBytes());
      }
    }

    return delegate.load(key);
  }

  Future<void> _update(String key) async {
    evict(key);

    final request = Ignis.preload.load(paths: [key]);

    try {
      await request;
    } catch (error) {
      debugPrint('[IGNIS] Failed to reload "$key". ($error)');
      return;
    } finally {
      request.dispose();
    }

    if (request.value.accepted == 0) {
      // Nothing is registered on Ignis.preload, or every loader filtered this
      // out, as with editor scratch files in the assets directory.
      debugPrint('[IGNIS] No loader accepted "$key".');
      return;
    }

    debugPrint('[IGNIS] Reloaded "$key".');
  }
}
