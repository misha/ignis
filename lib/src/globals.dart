import 'dart:async';

import 'package:flutter/services.dart';
import 'package:ignis/src/assets/cache.dart';
import 'package:ignis/src/assets/preload.dart';

/// Namespace for global Ignis objects.
abstract final class Ignis {
  /// The asset bundle used across Ignis.
  static AssetBundle bundle = rootBundle;

  static Cache _cache = Cache();

  /// Asset cache used by various Ignis nodes.
  static Cache get cache => _cache;

  static set cache(Cache value) {
    if (identical(_cache, value)) return;
    _cache.dispose();
    _cache = value;
  }

  static Preload _preload = Preload();

  /// Asset preload used to fill the [cache].
  static Preload get preload => _preload;

  static set preload(Preload value) {
    if (identical(_preload, value)) return;
    _preload.dispose().ignore();
    _preload = value;
  }
}
