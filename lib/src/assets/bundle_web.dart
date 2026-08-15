import 'package:flutter/services.dart';

/// The `dart:io`-free stand-in for [LiveAssetBundle].
///
/// Live reloading needs a filesystem to watch, so on the web this is a plain
/// pass-through to [rootBundle]: [start] reports false and nothing is ever
/// reloaded. It exists so installing a live bundle compiles everywhere.
class LiveAssetBundle extends CachingAssetBundle {
  /// The project directory asset keys would be resolved against.
  final String root;

  /// Whether live reloading is currently active. Always false here.
  bool get isRunning => false;

  LiveAssetBundle({
    String? root,
    String? pubspec,
    String? assets,
  }) : root = root ?? '';

  /// Does nothing, and reports that live reloading did not start.
  Future<bool> start() async => false;

  Future<void> stop() async {
    // Nothing to do.
  }

  Future<void> dispose() async {
    // Nothing to do.
  }

  @override
  Future<ByteData> load(String key) => rootBundle.load(key);
}
