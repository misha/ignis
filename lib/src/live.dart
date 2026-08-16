part of 'core.dart';

/// Keeps whatever [create] returns alive across [Node.build] passes, under
/// [name].
///
/// A pass re-runs from the top every time, so everything it builds is built
/// again. That is the point for closures and configuration, and fatal for
/// anything with state worth keeping. Wrapping it in [live] runs [create]
/// exactly once and hands back the same value on every later pass:
///
/// ```dart
/// final square = add(live(#square, () {
///   return ShapeNode(shape: .square(100));
/// }));
///
/// square.paint.color = _COLOR;
/// ```
///
/// Editing `_COLOR` repaints the existing square, because that line re-runs.
/// Editing the shape does nothing, because that closure does not.
///
/// **The name is the whole mechanism.** It is what survives a hot reload, so
/// it must be stable and unique within the node. Unlike a positional scheme,
/// nothing about it cares where the call sits: insert lines above it, reorder
/// it, wrap it in an `if`, move it into a loop, and the value is still found.
/// Rename it and you get a new one, which is how you force a rebuild.
///
/// Pass [keys] to tie the value to something instead, and it is rebuilt
/// whenever they stop comparing equal - the same edit as above, without
/// having to invent a new name for it:
///
/// ```dart
/// add(live(#square, () {
///   return ShapeNode(shape: .square(_SIZE));
/// }, [_SIZE]));
/// ```
///
/// Anything not declared by a pass is dropped once that pass finishes, and a
/// [Node] is detached on the way out - as is a value its [keys] replaced. So
/// deleting the declaration removes what it made, and a pass that throws
/// part-way sweeps nothing.
///
/// Only valid inside [Node.build].
T live<T>(
  Symbol name,
  T Function() create, [
  List<Object?> keys = const [],
]) {
  final builder = Node._builder;

  if (builder == null) {
    throw StateError('live() is only available inside Node.build.');
  }

  return builder._keep(name, create, keys) as T;
}

/// One [live] value, and the keys deciding whether it is kept.
final class _Kept {
  final Object? value;
  final List<Object?> keys;

  const _Kept(this.value, this.keys);

  /// Whether a declaration with [keys] may keep this value.
  bool matches(List<Object?> other) {
    final own = keys;
    if (identical(own, other)) return true;
    if (own.length != other.length) return false;

    for (var i = 0; i < own.length; i += 1) {
      final left = own[i];
      final right = other[i];

      if (left is num && right is num) {
        // NaN never equals itself, so two of them have to be paired directly.
        if (left.isNaN && right.isNaN) continue;

        // 0.0 and -0.0 are equal, but they are not the same key.
        if (left == 0 && right == 0) {
          if (left.isNegative != right.isNegative) return false;
          continue;
        }
      }

      if (left != right) return false;
    }

    return true;
  }
}
