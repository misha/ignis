part of 'core.dart';

/// Call to undo whatever a hook set up.
typedef Cleanup = void Function();

/// Why a node's next [Node.tick] is a full hook pass rather than a replay.
enum BuildCause {
  /// The node was just mounted, so this is its first pass.
  mount,

  /// The Dart VM hot reloaded, so the shape of [Node.tick] may have changed.
  reload,

  /// An asset changed. Code did not, so the shape of [Node.tick] cannot have.
  assets,
}

/// One numbered position in a node's hook slots.
///
/// Slots are matched by the order their hooks were called in, so a node's
/// hooks must be used unconditionally and always in the same sequence.
///
/// Hooks own lifecycle, never values: a node's state lives in ordinary
/// fields, which the rest of the tree can reach and a hot reload leaves
/// alone on its own.
sealed class _Slot {
  void dispose() {
    // Nothing to do.
  }
}

final class _EffectSlot extends _Slot {
  List<Object?>? keys;
  Cleanup? cleanup;

  _EffectSlot(this.keys);

  void run(Cleanup? Function() effect) {
    cleanup?.call();
    cleanup = effect();
  }

  @override
  void dispose() => cleanup?.call();
}

final class _ChildSlot<T extends Node> extends _Slot {
  final T child;
  List<Object?> keys;

  _ChildSlot(this.child, this.keys);

  @override
  void dispose() => child.detach();
}

/// Whether a slot keyed on [previous] may be kept when handed [next].
///
/// Null on either side means "unkeyed", which keeps the slot but re-runs
/// whatever it holds — that is how a hook picks up freshly compiled code.
bool _keep(List<Object?>? previous, List<Object?>? next) {
  if (identical(previous, next)) return true;
  if (previous == null || next == null || previous.length != next.length) {
    return false;
  }

  for (var i = 0; i < previous.length; i += 1) {
    final left = previous[i];
    final right = next[i];

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
