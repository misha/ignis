part of 'core.dart';

/// Call to undo whatever a hook set up.
typedef Cleanup = void Function();

/// Why a [Node.build] pass is running.
enum BuildCause {
  /// The node was just mounted, so this is its first pass.
  mount,

  /// The Dart VM hot reloaded, so the shape of [Node.build] may have changed.
  reload,

  /// An asset changed. Code did not, so the shape of [Node.build] cannot have.
  assets,
}

/// The declaration of one unit of state or behavior inside [Node.build].
///
/// A hook is immutable and disposable: a fresh one is created on every pass,
/// and it exists only to describe what its [HookState] should do. The state is
/// the half that survives re-execution.
///
/// Hooks are matched to their state by call order, so they must be used
/// unconditionally and always in the same sequence. Adding, removing, or
/// reordering them is legal across a hot reload, and illegal otherwise.
@immutable
abstract class Hook<R> {
  /// Creates a hook whose state is reused while [keys] compare equal.
  const Hook({this.keys});

  /// The values deciding whether this hook's state is reused or replaced.
  ///
  /// An empty list reuses the state forever. A null list reuses it too, but
  /// reports the new hook through [HookState.didUpdateHook] on every pass,
  /// which is how a hook re-runs after a reload.
  final List<Object?>? keys;

  /// Creates the mutable state backing this hook.
  HookState<R, Hook<R>> createState();

  /// Whether [next] may take over [previous]'s state instead of replacing it.
  static bool shouldPreserveState(Hook<Object?> previous, Hook<Object?> next) {
    final a = previous.keys;
    final b = next.keys;
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;

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
}

/// The half of a [Hook] that outlives a [Node.build] pass.
abstract class HookState<R, T extends Hook<R>> {
  Node? _node;
  T? _hook;

  /// The node whose [Node.build] created this state.
  Node get node => _node!;

  /// The hook that most recently described this state.
  T get hook => _hook!;

  /// Called once, when this state is created.
  void initHook() {
    // Nothing to do.
  }

  /// Called when a new [hook] took this state over, which happens on every
  /// pass whose hook preserved it.
  void didUpdateHook(T previous) {
    // Nothing to do.
  }

  /// Called on every pass, including the one that created this state.
  R build();

  /// Called when this state is discarded, by teardown or by replacement.
  void dispose() {
    // Nothing to do.
  }
}

// #region Effect

final class _EffectHook extends Hook<void> {
  final Cleanup? Function() effect;

  const _EffectHook(this.effect, {super.keys});

  @override
  _EffectHookState createState() => .new();
}

final class _EffectHookState extends HookState<void, _EffectHook> {
  Cleanup? _cleanup;

  @override
  void initHook() => _cleanup = hook.effect();

  @override
  void didUpdateHook(_EffectHook previous) {
    // Keyed effects are preserved on purpose; a state that survives its keys
    // is a state that should not re-run.
    if (hook.keys != null) return;
    _cleanup?.call();
    _cleanup = hook.effect();
  }

  @override
  void build() {
    // Nothing to do.
  }

  @override
  void dispose() => _cleanup?.call();
}

// #endregion

// #region Tick

final class _TickHook extends Hook<void> {
  final void Function(double dt) tick;

  const _TickHook(this.tick);

  @override
  _TickHookState createState() => .new();
}

final class _TickHookState extends HookState<void, _TickHook> {
  @override
  void build() => node._addTick(hook.tick);
}

// #endregion

// #region Child

final class _ChildHook<T extends Node> extends Hook<T> {
  final T Function() create;

  const _ChildHook(this.create, {super.keys});

  @override
  _ChildHookState<T> createState() => .new();
}

final class _ChildHookState<T extends Node> extends HookState<T, _ChildHook<T>> {
  late final T child;

  @override
  void initHook() {
    child = hook.create();
    node.add(child);
  }

  @override
  T build() => child;

  @override
  void dispose() => child.detach();
}

// #endregion
