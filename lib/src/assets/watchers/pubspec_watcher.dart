// SPDX-AI-Disclosure: ai-assisted

import 'dart:async';
import 'dart:io';

import 'package:ignis/src/assets/watchers/asset_watcher.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Two-level watcher for a Flutter project's declared assets.
///
///   1. First level watches `pubspec.yaml`, parsing out the `assets` manifest.
///   2. Second level hands that manifest to an [AssetWatcher], rebuilt from
///      scratch whenever the manifest changes.
///
/// The manifest is the only source of truth for what gets watched, so declaring
/// a new asset directory takes effect without a restart.
///
/// Changes are reported as project-relative paths, which are exactly the keys
/// Flutter uses for those assets. Matching follows Flutter's own rule as closely
/// as possible: a directory entry like `assets/` globs one level deep, so a
/// change in `assets/nested/` is not reported. Your app could not load it
/// either.
///
/// Only functions in debug builds and only when run on the same host as the app.
class PubspecWatcher {
  PubspecWatcher({
    required String pubspecPath,
  }) : pubspec = File(pubspecPath),
       root = p.dirname(p.absolute(pubspecPath));

  final File pubspec;

  /// The project directory the manifest and reported paths are relative to.
  final String root;

  final StreamController<String> _updates = .broadcast();

  /// The project-relative path of each asset that changes.
  Stream<String> get updates => _updates.stream;

  StreamSubscription? _pubspecSubscription;
  StreamSubscription? _changesSubscription;
  AssetWatcher? _assets;
  Set<String> _manifest = const {};
  bool _running = false;

  bool get isRunning => _running;

  /// The manifest entries currently being watched, relative to [root].
  Iterable<String> get watching {
    final assets = _assets;
    if (assets == null) return const [];
    return assets.watching.map((path) => p.relative(path, from: root));
  }

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
        ?_changesSubscription?.cancel(),
        ?_assets?.dispose(),
      ]);
    } finally {
      _pubspecSubscription = null;
      _changesSubscription = null;
      _assets = null;
      _manifest = const {};
      _running = false;
    }
  }

  Future<void> dispose() async {
    await Future.wait([
      stop(),
      _updates.close(),
    ]);
  }

  /// Re-reads the manifest, rebuilding the asset watcher if it changed.
  Future<void> _sync() async {
    final Set<String> manifest;

    try {
      manifest = await _read();
    } catch (_) {
      // A pubspec being edited is routinely invalid mid-keystroke. Keep
      // watching whatever the last readable manifest declared.
      return;
    }

    if (manifest.length == _manifest.length && manifest.containsAll(_manifest)) {
      return;
    }

    _manifest = manifest;
    await _rebuild();
  }

  /// The `flutter: assets:` entries, exactly as the pubspec declares them.
  Future<Set<String>> _read() async {
    final data = await pubspec.readAsString();
    final yaml = loadYaml(data);
    if (yaml is! YamlMap) return const {};
    final flutter = yaml['flutter'];
    if (flutter is! YamlMap) return const {};
    final assets = flutter['assets'];
    if (assets is! YamlList) return const {};

    return {
      for (final asset in assets) //
        if (asset is String) //
          asset,
    };
  }

  Future<void> _rebuild() async {
    await Future.wait([
      ?_changesSubscription?.cancel(),
      ?_assets?.dispose(),
    ]);

    final assets = AssetWatcher([
      for (final entry in _manifest) //
        p.join(root, entry),
    ]);

    _changesSubscription = assets.changes.listen(_handle);
    _assets = assets;
    await assets.start();
  }

  void _handle(String path) {
    final asset = p.relative(path, from: root);
    if (_declares(asset)) _updates.add(asset);
  }

  /// Whether the manifest declares [asset], by Flutter's own rule.
  ///
  /// A directory entry globs exactly one level deep, so it claims its immediate
  /// children and nothing further down.
  bool _declares(String asset) {
    final parent = p.dirname(asset);

    return _manifest.any((entry) {
      if (entry.endsWith('/')) {
        return p.equals(entry, parent);
      } else {
        return p.equals(entry, asset);
      }
    });
  }
}
