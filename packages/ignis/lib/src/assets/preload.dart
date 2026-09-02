// SPDX-AI-Disclosure: none

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ignis/src/assets/loader.dart';
import 'package:ignis/src/globals.dart';
import 'package:pool/pool.dart';

part 'preload_request.dart';
part 'preload_snapshot.dart';

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
///   ..register(ImageLoader()..extensions(['.png']))
///   ..register(JsonLoader()..extensions(['.json']));
///
/// final request = await Ignis.preload.load(manifest: true);
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
  /// await Preload.run(loaders: [ImageLoader()], manifest: true);
  /// ```
  ///
  /// The request is still returned, so progress is available for as long as the
  /// load is running. Unlike [load], do not dispose it yourself, and do not
  /// listen to it after it completes.
  static PreloadRequest run({
    required Iterable<Loader> loaders,
    Iterable<String> paths = const [],
    bool manifest = false,
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
  /// Enabling [manifest] loads everything in the [Ignis.bundle] manifest,
  /// while [paths] can be used for a more targeted preload. Each loader's own
  /// filters decide which of them it actually applies to.
  ///
  /// The result reports progress and completes as a [Future]. Calls may overlap
  /// freely, since the pool is what bounds the work.
  PreloadRequest load({
    Iterable<String> paths = const [],
    bool manifest = false,
  }) {
    return PreloadRequest._(
      _pool,
      .of(_loaders),
      manifest,
      .of(paths),
    );
  }

  /// Releases the worker pool. Loading afterwards throws.
  Future<void> dispose() => _pool.close();
}
