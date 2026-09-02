// SPDX-AI-Disclosure: none

part of 'preload.dart';

/// A single [Preload.load] in flight.
///
/// It publishes its state as a [PreloadSnapshot] through [value], notifies its
/// listeners as assets land, and completes as a [Future] of the terminal
/// snapshot. A failure is delivered to every awaiter and recorded on the
/// snapshot. Dispose it once you are done with it:
///
/// ```dart
/// final request = Ignis.preload.load(manifest: true);
/// // ...drive a progress bar from `request.value`...
/// await request;
/// request.dispose();
/// ```
///
/// Disposing a running request cancels it: assets not yet loading are skipped,
/// in-flight ones finish into the cache, and listeners and awaiters receive
/// one final snapshot with [PreloadSnapshot.cancelled] set.
class PreloadRequest //
    extends ValueNotifier<PreloadSnapshot>
    implements Future<PreloadSnapshot> {
  final Pool _pool;
  final List<Loader> _loaders;

  final _completer = Completer<PreloadSnapshot>();
  bool _disposed = false;

  PreloadRequest._(
    this._pool,
    this._loaders,
    bool manifest,
    List<String> assets,
  ) : super(const .waiting()) {
    // A failure reaches awaiters through [then] and pollers through [value].
    _completer.future.ignore();
    _run(manifest, assets);
  }

  Future<void> _run(bool manifest, List<String> assets) async {
    _publish(value.copyWith(total: assets.length));

    try {
      if (manifest) {
        final listing = await _pool.withResource(() {
          return AssetManifest.loadFromAssetBundle(Ignis.bundle);
        });

        final discovered = listing.listAssets();
        assets.addAll(discovered);
        _publish(value.copyWith(total: value.total + discovered.length));
      }

      if (_disposed) {
        return;
      }

      await Future.wait([
        for (final asset in assets) //
          _load(asset),
      ]);
    } catch (exception, stack) {
      _complete(value.copyWith(done: true, error: exception, stackTrace: stack));
      return;
    }

    _complete(value.copyWith(done: true));
  }

  Future<void> _load(String asset) async {
    if (_disposed) {
      return;
    }

    try {
      await _pool.withResource(() async {
        if (_disposed) {
          return;
        }

        final context = LoadingContext(
          cache: Ignis.cache,
          bundle: Ignis.bundle,
          asset: asset,
        );

        var handled = false;

        for (final loader in _loaders) {
          if (_disposed) {
            return;
          }

          if (!loader.accepts(context)) continue;
          handled = true;
          await loader.load(context);
        }

        if (handled) {
          _publish(value.copyWith(accepted: value.accepted + 1));
        }
      });
    } finally {
      _publish(value.copyWith(completed: value.completed + 1));
    }
  }

  void _publish(PreloadSnapshot snapshot) {
    if (_disposed) {
      return;
    }

    value = snapshot;
  }

  void _complete(PreloadSnapshot snapshot) {
    if (_completer.isCompleted) {
      return;
    }

    _publish(snapshot);
    final error = snapshot.error;

    if (error == null) {
      _completer.complete(snapshot);
    } else {
      _completer.completeError(error, snapshot.stackTrace);
    }
  }

  /// Cancels the load if it is still running, then discards this notifier.
  @override
  void dispose() {
    if (!_completer.isCompleted) {
      value = value.copyWith(done: true, cancelled: true);
      _completer.complete(value);
    }

    _disposed = true;
    super.dispose();
  }

  @override
  Stream<PreloadSnapshot> asStream() => _completer.future.asStream();

  @override
  Future<PreloadSnapshot> catchError(Function onError, {bool Function(Object)? test}) =>
      _completer.future.catchError(onError, test: test);

  @override
  Future<R> then<R>(FutureOr<R> Function(PreloadSnapshot) onValue, {Function? onError}) =>
      _completer.future.then(onValue, onError: onError);

  @override
  Future<PreloadSnapshot> timeout(
    Duration limit, {
    FutureOr<PreloadSnapshot> Function()? onTimeout,
  }) => _completer.future.timeout(limit, onTimeout: onTimeout);

  @override
  Future<PreloadSnapshot> whenComplete(FutureOr<void> Function() action) =>
      _completer.future.whenComplete(action);
}
