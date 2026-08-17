import 'package:flutter/services.dart';

/// The `dart:io`-free stand-in for [LocalAssetBundle].
///
/// Live reloading needs a filesystem to watch, so on the web this is a plain
/// pass-through to [delegate]: [start] reports false and nothing is ever
/// reloaded. It exists so installing a local bundle compiles everywhere.
class LocalAssetBundle extends CachingAssetBundle {
  /// The project directory asset keys would be resolved against.
  final String root;

  /// Where every key is loaded from.
  final AssetBundle delegate;

  /// Whether live reloading is currently active. Always false here.
  bool get isRunning => false;

  /// The manifest entries being watched. Always empty here.
  Iterable<String> get watching => const [];

  LocalAssetBundle({
    String? root,
    AssetBundle? delegate,
  }) : root = root ?? '',
       delegate = delegate ?? rootBundle;

  /// Does nothing, and reports that live reloading did not start.
  Future<bool> start() async => false;

  Future<void> stop() async {}

  Future<void> dispose() async {}

  @override
  Future<ByteData> load(String key) => delegate.load(key);
}
