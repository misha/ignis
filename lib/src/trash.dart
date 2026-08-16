part of 'core.dart';

/// A node's bag of teardown callbacks for the current [Node.build] pass.
///
/// Whatever a pass creates and has to release again - a painter, a gesture
/// recognizer, a subscription, a registration with some system - is thrown in
/// the bag, and comes back out when the next pass supersedes that one or the
/// node unmounts.
///
/// ```dart
/// painter = TextPainter(text: span);
/// trash << painter.dispose;
/// ```
///
/// Unlike a [Hook], the bag has no shape. It is emptied and refilled by every
/// pass, so it may be filled from inside an `if`, a loop, or a helper.
///
/// Prefer a tear-off, as above. A closure works too, and some cleanups need
/// one:
///
/// ```dart
/// trash << () => system.deregister(this);
/// ```
///
/// Just never let one read a field the next pass reassigns - it would release
/// that pass's object instead of this one's.
class Trash {
  List<Cleanup>? _cleanups;

  /// Defers [cleanup] until this bag is emptied.
  void operator <<(Cleanup cleanup) {
    (_cleanups ??= []).add(cleanup);
  }

  /// Runs every deferred cleanup, most recently thrown in first.
  ///
  /// Guarded, like a [Hook] disposal: one bad cleanup must not strand the rest
  /// of the bag. The list is taken first, so a cleanup that defers more work
  /// fills a fresh bag rather than one being emptied out from under it.
  void _empty() {
    final cleanups = _cleanups;
    if (cleanups == null || cleanups.isEmpty) return;
    _cleanups = null;

    for (var i = cleanups.length - 1; i >= 0; i -= 1) {
      try {
        cleanups[i]();
      } catch (exception, stack) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: exception,
            stack: stack,
            library: 'ignis',
            context: ErrorDescription('while emptying the trash'),
          ),
        );
      }
    }
  }
}
