import 'dart:async';

import 'package:flutter/services.dart';
import 'package:ignis/src/assets/cache.dart';
import 'package:ignis/src/core.dart';
import 'package:ignis/src/devices/keyboard.dart';
import 'package:ignis/src/assets/preload.dart';

// TODO: These want a single prefix between them, as `Ignis.prefix`. An asset
// string is the path `bundle` reads and the key `cache` stores under at once,
// and `preload` hands the same string to both, so an asset root has to be
// applied at one boundary and one only: prepended on the way to the bundle,
// absent from every key. Anything else gives one asset two names.

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

  /// Controls flags and settings for Ignis' debug features.
  static Debug debug = Debug();

  static Controls _controls = Controls()..attach(KeyboardDevice());

  /// Registers devices and routes their events to control handlers.
  ///
  /// The default instance comes with a [KeyboardDevice] attached.
  static Controls get controls => _controls;

  static set controls(Controls value) {
    if (identical(_controls, value)) return;
    _controls.dispose();
    _controls = value;
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
