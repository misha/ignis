part of 'core.dart';

/// A node's per-frame callbacks for the current [Node.build] pass.
///
/// Whatever the node should do every frame is thrown in the bag, and thrown
/// out again by the next pass:
///
/// ```dart
/// tick << (dt) => square.angle += _SPIN * dt;
/// ```
///
/// The only way a node runs per-frame code, and it reloads: the closure is
/// registered afresh by every pass, so an edited body is running the frame
/// after the save.
///
/// Like [Trash] and unlike [live], the bag has no identity. It is emptied and
/// refilled by every pass, so it may be filled from inside an `if`, a loop, or
/// a helper.
///
/// An extension type over the node itself, so the callbacks sit in a plain
/// field the frame path reads directly. The bag is syntax, not a hop.
extension type Tick(Node _node) {
  /// Runs [callback] with the elapsed seconds on every frame, until the pass
  /// that declared it is superseded.
  void operator <<(void Function(double dt) callback) {
    (_node._ticks ??= []).add(callback);
  }
}
