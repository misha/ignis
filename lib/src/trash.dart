part of 'core.dart';

/// Call to undo whatever was set up.
typedef Cleanup = void Function();

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
/// Like [Tick] and unlike [live], the bag has no identity. It is emptied and
/// refilled by every pass, so it may be filled from inside an `if`, a loop, or
/// a helper.
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
///
/// An extension type over the node itself, so the cleanups sit in a plain
/// field and the bag costs nothing to hand out.
extension type Trash(Node _node) {
  /// Defers [cleanup] until this bag is emptied.
  void operator <<(Cleanup cleanup) {
    (_node._trash ??= []).add(cleanup);
  }
}
