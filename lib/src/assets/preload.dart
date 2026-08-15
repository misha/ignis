import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ignis/src/assets/loader.dart';
import 'package:ignis/src/globals.dart';
import 'package:pool/pool.dart';

const _CONCURRENCY = 10;
const _TIMEOUT = Duration(seconds: 10);

/// A registry of [Loader]s, and the pool that runs them.
///
/// Register loaders once, then [load] whatever you need, whenever you need it.
/// Each call names its own assets and hands back a [PreloadRequest] to watch.
/// There is no difference between filling the cache at startup and replacing
/// one entry later; both go through the same loaders.
///
/// ```dart
/// Ignis.preload
///   ..register(Loader.image()..extensions(['.png']))
///   ..register(Loader.json()..extensions(['.json']));
///
/// await Ignis.preload.load(manifest: true);
/// ```
class Preload {
  final int concurrency;
  final Duration timeout;

  final Pool _pool;
  final List<Loader> _loaders = [];

  /// The loaders every loaded asset is fed through.
  Iterable<Loader> get loaders => _loaders;

  /// Creates a new preload.
  ///
  /// Assets are read from [Ignis.bundle] into [Ignis.cache], both resolved at
  /// load time so a bundle installed after configuration still applies.
  ///
  /// A pool is allocated to manage loading in parallel, subject to the target
  /// [concurrency] and a per-request [timeout]. By default, the pool permits
  /// 10 concurrent requests with a timeout of 10 seconds.
  Preload({
    this.concurrency = _CONCURRENCY,
    this.timeout = _TIMEOUT,
  }) : _pool = Pool(concurrency, timeout: timeout);

  /// Runs one load through a throwaway preload built from [loaders].
  ///
  /// Everything it creates is released once the load finishes, the returned
  /// request included, so this is for loads with nothing to keep around:
  ///
  /// ```dart
  /// await Preload.run([Loader.image()], manifest: true);
  /// ```
  ///
  /// The request is still returned, so progress is available for as long as the
  /// load is running. Unlike [load], do not dispose it yourself, and do not
  /// listen to it after it completes.
  static PreloadRequest run(
    List<Loader> loaders, {
    Iterable<String>? paths,
    bool? manifest,
    int concurrency = _CONCURRENCY,
    Duration timeout = _TIMEOUT,
  }) {
    final preload = Preload(
      concurrency: concurrency,
      timeout: timeout,
    );

    for (final loader in loaders) {
      preload.register(loader);
    }

    final request = preload.load(
      manifest: manifest,
      paths: paths,
    );

    // Listeners get their last notification before this runs, since the request
    // reports itself done on the way out of the load.
    request
        .whenComplete(() async {
          request.dispose();
          await preload.dispose();
        })
        // The caller awaits the request itself; this branch must not surface a
        // second, unhandled copy of the same failure.
        .ignore();

    return request;
  }

  /// Registers a [loader] to feed every loaded asset through.
  Preload register(Loader loader) {
    _loaders.add(loader);
    return this;
  }

  /// Loads assets through the registered loaders, replacing whatever
  /// [Ignis.cache] already holds for them.
  ///
  /// Name them with [manifest] to take everything in the [Ignis.bundle]
  /// manifest, and [paths] for named ones. Each loader's own filters decide
  /// which of them it actually applies to.
  ///
  /// The result reports progress and completes as a [Future]. Calls may overlap
  /// freely, since the pool is what bounds the work.
  PreloadRequest load({
    bool? manifest,
    Iterable<String>? paths,
  }) {
    return PreloadRequest._(
      _pool,
      // Snapshotted, so registering a loader mid-load cannot half-apply it.
      [..._loaders],
      manifest ?? false,
      [...?paths],
    );
  }

  /// Releases the worker pool. Loading afterwards throws.
  Future<void> dispose() => _pool.close();
}

/// A single [Preload.load] in flight.
///
/// It carries [progress], it notifies its listeners as assets land, and it
/// completes as a [Future]. Dispose it once you are done with it:
///
/// ```dart
/// final request = Ignis.preload.load(manifest: true);
/// // ...drive a progress bar from `request`...
/// await request;
/// request.dispose();
/// ```
class PreloadRequest extends ChangeNotifier implements Future<void> {
  final Pool _pool;
  final List<Loader> _loaders;

  late final Future<void> _future;

  int _total = 0;
  int _completed = 0;
  bool _done = false;
  bool _disposed = false;

  /// How many assets this load covers. Grows once a manifest is read.
  int get total => _total;

  /// How many of them have finished.
  int get completed => _completed;

  /// Whether the load has finished, successfully or not.
  bool get done => _done;

  /// How far along the load is, from 0 to 1.
  double get progress {
    if (_done) return 1;
    if (_total == 0) return 0;
    return _completed / _total;
  }

  PreloadRequest._(
    this._pool,
    this._loaders,
    bool manifest,
    List<String> assets,
  ) {
    _future = _run(manifest, assets);
  }

  Future<void> _run(bool manifest, List<String> assets) async {
    _total = assets.length;

    try {
      if (manifest) {
        final listing = await _pool.withResource(() {
          return AssetManifest.loadFromAssetBundle(Ignis.bundle);
        });

        final discovered = listing.listAssets();
        assets.addAll(discovered);
        _total += discovered.length;
        _notify();
      }

      await Future.wait([
        for (final asset in assets) //
          _load(asset),
      ]);
    } finally {
      _done = true;
      _notify();
    }
  }

  Future<void> _load(String asset) async {
    try {
      await _pool.withResource(() async {
        final context = LoadingContext(
          cache: Ignis.cache,
          bundle: Ignis.bundle,
          asset: asset,
        );

        for (final loader in _loaders) {
          await loader.run(context);
        }
      });
    } finally {
      _completed += 1;
      _notify();
    }
  }

  /// Notifies unless this was disposed mid-load, which is fair game for a load
  /// the game gave up on.
  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  Stream<void> asStream() => _future.asStream();

  @override
  Future<void> catchError(Function onError, {bool Function(Object)? test}) =>
      _future.catchError(onError, test: test);

  @override
  Future<R> then<R>(FutureOr<R> Function(void) onValue, {Function? onError}) =>
      _future.then(onValue, onError: onError);

  @override
  Future<void> timeout(Duration limit, {FutureOr<void> Function()? onTimeout}) =>
      _future.timeout(limit, onTimeout: onTimeout);

  @override
  Future<void> whenComplete(FutureOr<void> Function() action) => _future.whenComplete(action);
}
