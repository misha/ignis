// SPDX-AI-Disclosure: ai-generated

import 'package:flutter/services.dart';

/// The `dart:io`-free stand-in for [LocalAssetBundle].
///
/// Live reloading needs a filesystem to watch. On the web every load passes
/// through to [delegate] and [start] reports false. It exists so installing a
/// local bundle compiles everywhere.
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

  /// Always false on the web.
  Future<bool> start() async => false;

  Future<void> stop() async {}

  Future<void> dispose() async {}

  @override
  Future<ByteData> load(String key) => delegate.load(key);
}
