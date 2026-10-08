// SPDX-AI-Disclosure: none

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:ignis/src/assets/cache.dart';
import 'package:ignis/src/assets/preload.dart';
import 'package:ignis/src/core.dart';

// TODO: Create a configurable `Ignis.prefix`.

/// Namespace for global Ignis objects.
abstract final class Ignis {
  /// The asset bundle used across Ignis.
  static AssetBundle bundle = rootBundle;

  /// Asset cache used by various Ignis nodes.
  static Cache cache = Cache();

  /// Controls flags and settings for Ignis' debug features.
  static Debug debug = Debug();

  static Preload _preload = Preload();

  /// Asset preload used to fill the [cache].
  static Preload get preload => _preload;

  static set preload(Preload value) {
    if (identical(_preload, value)) return;
    _preload.dispose().ignore();
    _preload = value;
  }
}
