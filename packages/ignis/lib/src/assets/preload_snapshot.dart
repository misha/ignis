// SPDX-AI-Disclosure: none

part of 'preload.dart';

/// One `PreloadRequest`'s state at a point in time.
class PreloadSnapshot {
  /// How many assets the load covers. Grows if a manifest is read.
  final int total;

  /// How many assets have finished.
  final int completed;

  /// How many assets were accepted by at least one loader.
  ///
  /// The rest were filtered out, so nothing was cached for them. A load where
  /// this stays zero did no work at all, usually because no loader was
  /// registered for that kind of asset.
  final int accepted;

  /// Whether the load has finished, successfully or not.
  final bool done;

  /// Whether the load was cancelled by disposing its request early.
  final bool cancelled;

  /// What the load failed with, or null while it runs or once it succeeds.
  final Object? error;

  /// Where the load failed, or null while it runs or once it succeeds.
  final StackTrace? stackTrace;

  const PreloadSnapshot({
    required this.total,
    required this.completed,
    required this.accepted,
    required this.done,
    this.cancelled = false,
    this.error,
    this.stackTrace,
  });

  /// A load that has not started.
  const PreloadSnapshot.waiting()
    : this(
        total: 0,
        completed: 0,
        accepted: 0,
        done: false,
      );

  /// Whether the load failed.
  bool get hasError => error != null;

  /// Whether the load finished with every asset it covers.
  bool get succeeded => done && !cancelled && !hasError;

  /// How far along the load is, from 0 to 1.
  double get progress {
    if (done) return 1;
    if (total == 0) return 0;
    return completed / total;
  }

  PreloadSnapshot copyWith({
    int? total,
    int? completed,
    int? accepted,
    bool? done,
    bool? cancelled,
    Object? error,
    StackTrace? stackTrace,
  }) {
    return PreloadSnapshot(
      total: total ?? this.total,
      completed: completed ?? this.completed,
      accepted: accepted ?? this.accepted,
      done: done ?? this.done,
      cancelled: cancelled ?? this.cancelled,
      error: error ?? this.error,
      stackTrace: stackTrace ?? this.stackTrace,
    );
  }
}
