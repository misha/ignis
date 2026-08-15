import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ignis/src/assets/cache.dart';
import 'package:ignis/src/assets/loader.dart';
import 'package:ignis/src/globals.dart';
import 'package:pool/pool.dart';

/// Loads assets into a cache with bounded concurrency.
///
/// Add [manifest]s, [paths], or a one-off [path], then call [load].
///
/// A preload runs exactly once. Its resources are released when [run] finishes.
class Preload extends ChangeNotifier {
  final Cache cache;
  final int concurrency;
  final Duration timeout;

  final Pool _pool;
  final List<_Request> _requests = [];

  int _total = 0;
  int _completed = 0;
  double _progress = 0;
  bool _started = false;
  bool _done = false;

  int get total => _total;
  int get completed => _completed;
  double get progress => _progress;
  bool get done => _done;

  /// Creates a new preload for the given [cache].
  ///
  /// If no cache is provided, the default cache at [Ignis.cache] is used.
  ///
  /// A pool is allocated to manage loading in parallel, subject to the target
  /// [concurrency] and a per-request [timeout]. By default, the pool permits
  /// 10 concurrent requests with a timeout of 10 seconds.
  Preload({
    Cache? cache,
    this.concurrency = 10,
    this.timeout = const Duration(seconds: 10),
  }) : cache = cache ?? Ignis.cache,
       _pool = Pool(concurrency, timeout: timeout);

  /// Adds the assets from the [bundle]'s manifest to this preload, loaded
  /// using [loader].
  ///
  /// If the [bundle] is not supplied, the global bundle from the [Ignis]
  /// class is used instead.
  Preload manifest(
    Loader loader, {
    AssetBundle? bundle,
  }) {
    _checkNotStarted();

    _requests.add(
      _ManifestRequest(
        bundle ?? Ignis.bundle,
        loader,
      ),
    );

    return this;
  }

  /// Adds a collection of [paths] to this preload, loaded using [loader].
  ///
  /// If the [bundle] is not supplied, the global bundle from the [Ignis]
  /// class is used instead.
  Preload paths(
    Loader loader,
    Iterable<String> paths, {
    AssetBundle? bundle,
  }) {
    _checkNotStarted();

    _requests.add(
      _PathsRequest(
        bundle ?? Ignis.bundle,
        loader,
        .unmodifiable(paths),
      ),
    );

    return this;
  }

  /// Adds a single [path] to this preload, loaded using [loader].
  ///
  /// If the [bundle] is not supplied, the global bundle from the [Ignis]
  /// class is used instead.
  Preload path(
    Loader loader,
    String path, {
    AssetBundle? bundle,
  }) {
    _checkNotStarted();

    _requests.add(
      _PathRequest(
        bundle ?? Ignis.bundle,
        loader,
        path,
      ),
    );

    return this;
  }

  /// Loads all scheduled assets and releases this preload's resources.
  ///
  /// The returned future completes when preloading is [done].
  ///
  /// Internally, the worker pool is released once the future is completed. To
  /// complete disposal of this object and deactivate the [Listenable]
  /// implementation too, you must also call [dispose] afterwards. This is
  /// recommended for applications with multiple preloads.
  Future<void> run() async {
    _checkNotStarted();
    _started = true;

    for (final request in _requests) {
      switch (request) {
        case _ManifestRequest(:final bundle, :final loader):
          await _scheduleManifest(bundle, loader);

        case _PathsRequest(:final bundle, :final loader, paths: final assets):
          for (final asset in assets) {
            _scheduleAsset(bundle, loader, asset);
          }

        case _PathRequest(:final bundle, :final loader, path: final asset):
          _scheduleAsset(bundle, loader, asset);
      }
    }

    try {
      await _pool.close();
    } finally {
      _progress = 1;
      _done = true;
      notifyListeners();
    }
  }

  Future<void> _scheduleManifest(AssetBundle bundle, Loader loader) async {
    _total += 1;

    try {
      final manifest = await _pool.withResource(() {
        return AssetManifest.loadFromAssetBundle(bundle);
      });

      for (final asset in manifest.listAssets()) {
        _scheduleAsset(bundle, loader, asset);
      }
    } finally {
      _completed += 1;
      _progress = _completed / _total;
      notifyListeners();
    }
  }

  void _scheduleAsset(AssetBundle bundle, Loader loader, String asset) async {
    _total += 1;

    try {
      await _pool.withResource(() {
        return loader.run(
          .new(
            cache: cache,
            bundle: bundle,
            asset: asset,
          ),
        );
      });
    } finally {
      _completed += 1;
      _progress = _completed / _total;
      notifyListeners();
    }
  }

  void _checkNotStarted() {
    if (_started) {
      throw StateError('Preload has already started.');
    }
  }

  /// Waits for the preload to finish, then releases [Listenable] resources.
  @override
  Future<void> dispose() async {
    try {
      await _pool.close();
    } finally {
      super.dispose();
    }
  }
}

sealed class _Request {
  const _Request();
}

class _ManifestRequest extends _Request {
  final AssetBundle bundle;
  final Loader loader;

  const _ManifestRequest(this.bundle, this.loader);
}

class _PathsRequest extends _Request {
  final AssetBundle bundle;
  final Loader loader;
  final List<String> paths;

  const _PathsRequest(this.bundle, this.loader, this.paths);
}

class _PathRequest extends _Request {
  final AssetBundle bundle;
  final Loader loader;
  final String path;

  const _PathRequest(this.bundle, this.loader, this.path);
}
