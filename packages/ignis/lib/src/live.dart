part of 'core.dart';

/// What a [Node.keep] declaration is filed under: its name, plus the id that
/// separates one member of a collection from the next.
typedef _Key = (Symbol name, Object? id);

/// One [Node.keep] value, the keys deciding whether it is kept, and how to end
/// it once it is not.
final class _Kept {
  final Object? value;
  final List<Object?> keys;
  final Cleanup? dispose;

  /// The runtime type of the closure that made [value], which names what that
  /// closure builds even where the call site widened it away.
  final Type shape;

  const _Kept(this.value, this.keys, this.dispose, this.shape);

  /// Whether a declaration carrying [other] may keep this value.
  bool matches(List<Object?> other) => _sameKeys(keys, other);

  /// Ends this value, however it asked to be ended.
  void discard() {
    if (value case final Node stale) stale.detach();
    dispose?.call();
  }
}

/// Whether two key lists mean the same thing, and so whether the value they
/// guard may be kept.
///
/// TODO: Maybe there's a deep value equality that does this even better?
bool _sameKeys(List<Object?> a, List<Object?> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;

  for (var i = 0; i < a.length; i += 1) {
    final left = a[i];
    final right = b[i];

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

/// Re-derives a node's [Node.build] on every reload, and grants [keep].
///
/// Without this, a node's body is built once and held: the children it added,
/// its closures, and its subscriptions all survive a reload untouched, as
/// though the whole pass sat inside one [keep] block. Nothing that node
/// declares picks up an edit until the app restarts.
///
/// Mixing this in trades that for granularity. The body runs again on every
/// reload, so edits land, and [keep] names the individual values that should
/// carry across instead of the whole pass at once.
mixin Live on Node {
  Map<_Key, _Kept>? _kept;
  Set<_Key>? _claimed;

  /// Keeps whatever [create] returns alive across [build] passes, under [name].
  ///
  /// A pass re-runs from the top, so everything it builds is built again. That
  /// is the point for closures and configuration, and fatal for anything with
  /// state worth keeping. Naming it runs [create] exactly once and hands the
  /// same value back on every later pass:
  ///
  /// ```dart
  /// final square = keep(#square, () {
  ///   return ShapeNode(shape: .square(100));
  /// });
  ///
  /// square.paint.color = _COLOR;
  /// ```
  ///
  /// Editing `_COLOR` repaints the existing square, because that line re-runs.
  /// Editing the shape does nothing, because that closure does not.
  ///
  /// **The name is the whole mechanism.** Nothing about it cares where the call
  /// sits: insert lines above it, reorder it, wrap it in an `if`, move it into
  /// a loop, and the value is still found. Rename it to force a rebuild.
  ///
  /// Pass [keys] to tie the value to something instead, and it is rebuilt
  /// whenever they stop comparing equal:
  ///
  /// ```dart
  /// final square = keep(#square, () {
  ///   return ShapeNode(shape: .square(_SIZE));
  /// }, keys: [_SIZE]);
  /// ```
  ///
  /// Pass [id] to name a collection one member at a time. A member arriving in
  /// the data is built, one leaving is swept, and one that stays keeps
  /// everything it accumulated:
  ///
  /// ```dart
  /// final enemies = [
  ///   for (final spawn in level.spawns)
  ///     keep(#enemy, () => Enemy(spawn), id: spawn.id),
  /// ];
  /// ```
  ///
  /// Ids have to be stable. Keying on a loop index puts every member after a
  /// removal onto the value in front of it.
  ///
  /// Anything a pass stops declaring is dropped once that pass finishes: a
  /// [Node] is detached, and [dispose] runs if it was given. Reach for
  /// [dispose] rather than [trash] here, since the trash empties with every
  /// pass and a kept value outlives them. A pass that throws part-way sweeps
  /// nothing, so a node mid-edit keeps what it had.
  ///
  /// Only valid inside this node's own [build].
  @nonVirtual
  T keep<T>(
    Symbol name,
    T Function() create, {
    Object? id,
    List<Object?> keys = const [],
    void Function(T value)? dispose,
  }) {
    assert(
      identical(Node._builder, this),
      'keep() is only available inside this node\'s own build.',
    );

    final key = (name, id);
    final claimed = _claimed ??= {};

    // Outside an assert, so the claim still lands in a release build.
    final added = claimed.add(key);
    assert(added, 'Two keep() declarations in $runtimeType share $key.');
    final kept = _kept ??= {};
    final shape = create.runtimeType;
    final previous = kept[key];

    // A name that starts building something else is as finished as one the
    // keys replaced, so editing the type in place rebuilds rather than throws.
    if (previous != null && previous.shape == shape && previous.matches(keys)) {
      return previous.value as T;
    }

    // Whatever the keys replaced is as finished as one a pass dropped.
    previous?.discard();
    final value = _construct(create);

    Cleanup? cleanup;
    if (dispose != null) cleanup = () => dispose(value);

    kept[key] = _Kept(value, keys, cleanup, shape);
    return value;
  }

  /// Drops everything the pass that just finished stopped declaring.
  void _sweep() {
    final kept = _kept;
    if (kept == null || kept.isEmpty) return;
    final claimed = _claimed;

    kept.removeWhere((key, entry) {
      if (claimed != null && claimed.contains(key)) return false;
      entry.discard();
      return true;
    });
  }

  /// Runs [create] with no pass current, so a node built inside one does not
  /// hand its constructor's subscriptions to the node that built it.
  static T _construct<T>(T Function() create) {
    final builder = Node._builder;
    Node._builder = null;

    try {
      return create();
    } finally {
      Node._builder = builder;
    }
  }
}
