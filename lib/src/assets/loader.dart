import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:ignis/src/assets/cache.dart';

// #region Context

/// Represents a context in which an asset is loaded.
class LoadingContext {
  /// The cache into which the asset should be loaded.
  final Cache cache;

  /// The bundle that originated the asset path.
  final AssetBundle bundle;

  /// The actual path of the asset to be loaded.
  final String asset;

  const LoadingContext({
    required this.cache,
    required this.bundle,
    required this.asset,
  });
}

// #endregion

// #region Loaders

abstract class Loader {
  /// A loader that does nothing. Useful for stubbing and testing.
  factory Loader.noop() => NoopLoader();

  /// The built-in loader for JSON files.
  factory Loader.json() => JsonLoader();

  /// The built-in loader for images.
  factory Loader.image() => ImageLoader();

  final List<LoadingFilter> _filters = [];

  Loader();

  /// Appends a new [filter] to this loader.
  void filter(LoadingFilter filter) {
    _filters.add(filter);
  }

  /// Loads the asset specified by [context] if filtering passes.
  FutureOr<void> run(LoadingContext context) {
    if (_filters.every((filter) => filter(context))) {
      return load(context);
    }
  }

  /// Loads the asset specified by [context].
  FutureOr<void> load(LoadingContext context);
}

class NoopLoader extends Loader {
  @override
  void load(LoadingContext context) {
    // Nothing to do.
  }
}

class JsonLoader extends Loader {
  @override
  Future<void> load(LoadingContext context) async {
    final data = await context.bundle.loadString(context.asset);
    context.cache.add(context.asset, jsonDecode(data));
  }
}

class ImageLoader extends Loader {
  @override
  Future<void> load(LoadingContext context) async {
    final data = await context.bundle.load(context.asset);
    final bytes = Uint8List.view(data.buffer);
    final image = await decodeImageFromList(bytes);
    context.cache.add<Image>(context.asset, image);
  }
}

// #endregion

// #region Filters

abstract class LoadingFilter {
  const LoadingFilter();

  /// Returns true if this filter accepts the asset indicated by [context].
  bool call(LoadingContext context);
}

class _PrefixLoadingFilter extends LoadingFilter {
  final String prefix;

  const _PrefixLoadingFilter(this.prefix);

  @override
  bool call(LoadingContext context) => context.asset.startsWith(prefix);
}

class _ExtensionsLoadingFilter extends LoadingFilter {
  final List<String> extensions;

  _ExtensionsLoadingFilter(this.extensions);

  @override
  bool call(LoadingContext context) => //
      extensions.any((extension) => context.asset.endsWith(extension));
}

extension BuiltInFilters on Loader {
  /// Filters assets with the given [prefix].
  void prefix(String prefix) => filter(_PrefixLoadingFilter(prefix));

  /// Filters assets with the given [extensions].
  void extensions(List<String> extensions) => filter(_ExtensionsLoadingFilter(extensions));
}

// #endregion
