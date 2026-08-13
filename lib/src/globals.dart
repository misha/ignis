import 'package:flutter/services.dart';
import 'package:ignis/src/cache.dart';

/// Namespace for global Ignis objects.
abstract final class Ignis {
  /// The default asset bundle used across Ignis.
  static AssetBundle bundle = rootBundle;

  /// Asset storage used by various Ignis nodes.
  static Cache cache = Cache();
}
