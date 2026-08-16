part of 'core.dart';

/// Call to undo whatever was set up.
typedef Cleanup = void Function();

/// A node's teardown callbacks for its current [Node.build].
///
/// A one-liner goes in as a tear-off.
///
/// ```dart
/// painter = TextPainter(text: span);
/// trash << painter.dispose;
/// ```
///
/// Anything longer: write a local function and trash it. `dart format` will
/// happily mangle it otherwise.
///
/// ```dart
/// cd?.register(this);
///
/// void unregister() {
///   cd?.unregister(this);
///   cd = null;
/// }
///
/// trash << unregister;
/// ```
///
/// Emptied most-recent-first, so a teardown that emits must be trashed after
/// the handlers it will notify.
extension type Trash(Node _node) {
  /// Defers [cleanup] until this trash is emptied.
  void operator <<(Cleanup cleanup) {
    (_node._trash ??= []).add(cleanup);
  }
}
