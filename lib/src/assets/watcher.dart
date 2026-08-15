import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';
import 'package:yaml/yaml.dart';

/// Indicates the asset at [path] was updated.
///
/// The path is relative to the project root, so it doubles as the asset key
/// Flutter would use for it.
final class AssetUpdate {
  final String path;

  const AssetUpdate(this.path);
}

/// Two-level watcher for Flutter project assets.
///
///   1. First level watches `pubspec.yaml`, parsing out the `assets` manifest.
///   2. Second level recursively watches the specified assets path for changes.
///
/// Events are emitted in a way that follows Flutter behavior as closely as possible.
/// Specifically, changes inside the assets directory are only emitted as events when
/// they also satisfy one of the paths in the manifest, e.g. `assets/` only globs out
/// one level deep, `/assets/*`, rather than sending events despite your app not caring,
/// and more importantly not being able to use those assets to begin with.
///
/// Only functions in debug builds and only when run on the same host as the app.
class AssetWatcher {
  AssetWatcher({
    required String pubspecPath,
    required String assetsPath,
  }) : pubspec = File(pubspecPath),
       assets = Directory(assetsPath),
       root = p.dirname(p.absolute(pubspecPath));

  final File pubspec;
  final Directory assets;

  /// The project directory the manifest and emitted paths are relative to.
  final String root;

  final StreamController<AssetUpdate> _updates = .broadcast();
  Stream<AssetUpdate> get updates => _updates.stream;

  StreamSubscription? _pubspecSubscription;
  StreamSubscription? _assetsSubscription;
  Set<String> _manifest = const {};
  bool _running = false;

  bool get isRunning => _running;

  Future<bool> start() async {
    if (_running) {
      throw StateError('Already running.');
    }

    _running = true;

    try {
      if (!(await pubspec.exists())) {
        throw StateError('The specified pubspec file at "${pubspec.path}" does not exist.');
      }

      _pubspecSubscription = pubspec.watch().listen((event) async {
        if (event case FileSystemModifyEvent(:final contentChanged)) {
          if (!contentChanged) return;
          await _sync();
        }
      });

      await _sync();

      // TODO: Make this recoverable?
      if (!(await assets.exists())) {
        throw StateError('The specified assets directory at "${assets.path}" does not exist.');
      }

      // Cancelling the subscription closes this watcher, so [stop] releases it.
      final watcher = DirectoryWatcher(assets.path);

      _assetsSubscription = watcher.events.listen((event) async {
        if (await FileSystemEntity.isDirectory(event.path)) return;

        // The manifest is written relative to the project, so paths are matched
        // and emitted the same way. That makes them asset keys as they stand.
        final path = p.relative(p.absolute(event.path), from: root);
        final parent = p.dirname(path);
        final match = _manifest.any((asset) {
          if (asset.endsWith('/')) {
            return p.equals(asset, parent);
          } else {
            return p.equals(asset, path);
          }
        });

        if (match) {
          _updates.add(AssetUpdate(path));
        }
      });

      await watcher.ready;
      return true;
    } on Error {
      // Bailing out mid-start can leave the pubspec already subscribed.
      await stop();
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await Future.wait([
        ?_pubspecSubscription?.cancel(),
        ?_assetsSubscription?.cancel(),
      ]);
    } finally {
      _pubspecSubscription = null;
      _assetsSubscription = null;
      _running = false;
    }
  }

  Future<void> dispose() async {
    await Future.wait([
      stop(),
      _updates.close(),
    ]);
  }

  Future<void> _sync() async {
    final data = await pubspec.readAsString();
    final yaml = loadYaml(data);
    if (yaml is! YamlMap) return;
    final flutter = yaml['flutter'];
    if (flutter is! YamlMap) return;
    final assets = flutter['assets'];
    if (assets is! YamlList) return;

    _manifest = Set.unmodifiable([
      for (final asset in assets) //
        if (asset is String) //
          asset,
    ]);
  }
}
