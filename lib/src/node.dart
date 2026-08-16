part of 'core.dart';

/// The humble node.
///
/// **Overview**
///
/// Nodes are organized in an acyclic, directed tree with children ordered by
/// [priority]. A node is usually initialized once in its constructor, after
/// which it may be added and removed to other nodes repeatedly.
///
/// **Signals**
///
/// Nodes communicate time-sensitive events through signals: named, type-safe
/// message emitters. Use one to report an event to consumers, or as an input
/// to react to external events.
///
/// Conventionally, signals are prefixed with the word `on`. For example, a
/// collision signal should be named `onCollision`. This allows consumers to
/// have a natural-reading constructor, e.g. `onCollision(/* do stuff */);`.
///
/// **Scenes**
///
/// Nodes may be mounted to a [Scene], which drives them with a game loop. When
/// mounted, the scene will propagate through the entire subtree emitting the
/// [onMount] signal on each node, from top to bottom. Unmounting does the
/// reverse, emitting the [onUnmount] signal from the leaves upward.
///
/// **Tree**
///
/// Before being mounted, the [add], [remove], and [priority] tree operations
/// take effect immediately, allowing constructors to freely assemble a subtree
/// long before it goes live.
///
/// Once mounted, however, the same calls are instead merely enqueued. The
/// scene applies pending changes right before the next [update]. As a result,
/// operations for live node trees are always delayed a frame. Although
/// unintuitive, this queue allows the engine to mitigate modification
/// during iteration, and improves performance by batching the changes.
///
/// **Dependency Injection**
///
/// Nodes come integrated with a type-based dependency injection (DI) system.
/// A node may [provide] a value to its entire subtree, keyed by its type.
/// [read] resolves the nearest match, checking the node itself before its
/// [ancestors].
///
/// **Building**
///
/// Everything a node captures from outside itself - subscriptions, cached
/// assets, derived values, per-frame behavior - is declared in [build], which
/// runs on mount and is re-run whenever the world changes out from under the
/// live tree. State declared with a hook survives the re-run; the closures
/// around it do not, so they come back freshly compiled.
///
/// The re-run is a [reassemble] walk over the whole tree. Unlike [update] and
/// [render], it ignores the [enabled] flag, so even disabled nodes rebuild.
/// It happens in two, distinct situations:
///
///   - Whenever the `SceneWidget` reassembles in the Flutter tree.
///   - Whenever [Ignis.cache] changes, such as via the local asset bundle.
class Node {
  /// Creates a new node.
  ///
  /// [enabled] controls whether the node updates and renders.
  /// Defaults to true.
  ///
  /// [priority] controls this node's order when updating and rendering.
  /// Defaults to 0.
  ///
  /// If [children] are provided, they are immediately added to the node.
  Node({
    bool? enabled,
    int? priority,
    Iterable<Node> children = const [],
  }) : _priority = priority ?? 0,
       _enabled = enabled ?? true {
    addAll(children);
  }

  /// Updates this node by [dt] seconds.
  @visibleForOverriding
  void tick(double dt) {
    // Nothing to do.
  }

  /// Updates this node and its children by [dt] seconds.
  @nonVirtual
  void update(double dt) {
    if (!_enabled) return;
    tick(dt);

    final ticks = _ticks;

    if (ticks != null) {
      for (var i = 0; i < ticks.length; i += 1) {
        ticks[i](dt);
      }
    }

    final children = _egg?.nodes;
    if (children == null || children.isEmpty) return;

    for (final child in children) {
      child.update(dt);
    }
  }

  /// Renders this node and its children to [canvas].
  void render(Canvas canvas) {
    final children = _egg?.nodes;
    if (children == null || children.isEmpty) return;

    for (final child in children) {
      // Rendering is recursive, so this is the only way to stop it.
      // A disabled child must never have `render` called on it.
      if (child._enabled) {
        child.render(canvas);
      }
    }
  }

  /// Reassembles this node and its children, top down.
  ///
  /// Every node re-runs its [build], which is the only place to re-resolve
  /// what a node captured from outside itself. Tree operations the pass
  /// enqueues are flushed once the whole walk is done.
  @nonVirtual
  void reassemble(BuildCause cause) {
    _rebuild(cause);

    final children = _egg?.nodes;
    if (children == null || children.isEmpty) return;

    for (final child in children) {
      child.reassemble(cause);
    }
  }

  /// Renders the debug overlay for this node and its children to [canvas].
  void debugRender(Canvas canvas) {
    final children = _egg?.nodes;
    if (children == null || children.isEmpty) return;

    for (final child in children) {
      if (child._enabled) {
        child.debugRender(canvas);
      }
    }
  }

  // #region Enabled

  bool _enabled;

  /// Whether this node updates and renders. Defaults to true.
  bool get enabled => _enabled;

  /// Enables this node, so it resumes updating and rendering.
  @mustCallSuper
  void enable() => _enabled = true;

  /// Disables this node, so it stops updating and rendering.
  @mustCallSuper
  void disable() => _enabled = false;

  @nonVirtual
  set enabled(bool value) {
    if (value) {
      enable();
    } else {
      disable();
    }
  }

  // #endregion

  // #region Priority

  int _priority;

  /// This node's order in updating and rendering in its parent. Defaults to 0.
  int get priority => _priority;

  set priority(int value) {
    _priority = value;
    final target = parent;
    if (target == null) return;

    if (target.isMounted) {
      target.scene._tree._reposition(this, target);
    } else {
      target._reposition(this);
    }
  }

  // #endregion

  // #region Signals

  /// Emitted when this node is added to a [Scene].
  final onMount = Signal0();

  /// Emitted when this node is removed from a [Scene].
  final onUnmount = Signal0();

  // #endregion

  // #region Tree

  Scene? _scene;
  Egg? _egg;
  Node? _parent;
  Node? _pendingParent;
  bool _pendingRemoval = false;

  /// This node's owning scene. Only valid while [isMounted].
  Scene get scene {
    assert(_scene != null, 'This node is not mounted yet.');
    return _scene!;
  }

  /// True while this node is part of a mounted tree.
  bool get isMounted => _scene != null;

  /// This node's direct children.
  Iterable<Node> get children => _egg?.nodes ?? const [];

  /// This node's direct children of type [T], in [priority] order.
  ///
  /// The result is kept up to date as children come and go, so repeated calls
  /// cost nothing and allocate nothing. The first call for a given [T] pays
  /// one pass over [children] to build it.
  ///
  /// Returned as an [Iterable] over this node's live storage, so it reflects
  /// later changes but cannot be mutated through its interface.
  Iterable<T> query<T extends Node>() => (_egg ??= Egg()).query<T>();

  /// The parent that owns this node, or null when it is parentless.
  Node? get parent => _parent;

  /// True if this node has a non-null parent.
  bool get hasParent => parent != null;

  /// This node's ancestors in the tree.
  Iterable<Node> get ancestors sync* {
    var ancestor = parent;

    while (ancestor != null) {
      yield ancestor;
      ancestor = ancestor.parent;
    }
  }

  /// This node's descendants in depth-first preorder.
  Iterable<Node> get descendants sync* {
    for (final child in children) {
      yield child;
      yield* child.descendants;
    }
  }

  /// Checks if this node contains the [other] node in its tree.
  bool contains(Node other) => //
      descendants.any((descendant) => identical(descendant, other));

  /// Checks if this node owns the [other] node.
  bool owns(Node other) => identical(this, other.parent);

  /// True if [node] is (or soon will be) an ancestor of this node.
  bool cycles(Node node) {
    Node? current = this;

    while (current != null) {
      if (identical(current, node)) return true;
      current = current._parent ?? current._pendingParent;
    }

    return false;
  }

  void _own(Node node) {
    (_egg ??= Egg()).add(node);
    node._parent = this;
    node._pendingParent = null;
    final scene = _scene;
    if (scene != null) node._mount(scene);
  }

  void _disown(Node node) {
    try {
      if (node.isMounted) node._unmount();
    } finally {
      _egg?.remove(node);
      node._parent = null;
      node._pendingRemoval = false;
    }
  }

  void _reposition(Node node) => _egg?.reorder(node);

  // #endregion

  // #region Mounting

  void _mount(Scene scene) {
    // TODO: Assert null _scene?
    _scene = scene;
    _rebuild(.mount);
    onMount.emit();
    final children = _egg?.nodes;

    if (children != null && children.isNotEmpty) {
      for (final child in children) {
        child._mount(scene);
      }
    }
  }

  void _unmount() {
    // TODO: Assert non-null _scene?
    final children = _egg?.nodes;

    if (children != null && children.isNotEmpty) {
      for (final child in children) {
        child._unmount();
      }
    }

    onUnmount.emit();
    _disposeFrom(0);
    _hooks = null;
    _ticks = null;
    _scene = null;
    _dependencies = null;
  }

  // #endregion

  // #region Hooks

  List<HookState<Object?, Hook<Object?>>>? _hooks;
  List<void Function(double)>? _ticks;

  /// The slot [fuse] is about to fill, or -1 while no pass is running.
  int _cursor = -1;

  /// Why the pass currently running was started. Only ever read by [use], and
  /// only to decide whether a change in hook shape is legitimate.
  static BuildCause? _cause;

  /// Declares this node's state and behavior.
  ///
  /// Runs once on mount and again on every [reassemble], so anything declared
  /// here with a hook is refreshed when the world changes: handlers come back
  /// freshly compiled, values are re-read, and whatever the previous pass
  /// registered is torn down first.
  ///
  /// Hooks are matched by call order across passes, so they must be used
  /// unconditionally — never inside an `if`, a loop, or a closure. A whole
  /// class hierarchy shares one set of slots, which is why `super.build()` is
  /// required: skipping it drops whatever the superclass declared.
  @mustCallSuper
  @visibleForOverriding
  void build() {
    // Nothing to do.
  }

  /// Registers [hook] in the current [build] pass and returns its value.
  ///
  /// This is the primitive every `fuse` function is built out of; reach for it
  /// directly only when writing a [Hook] of your own.
  @nonVirtual
  R fuse<R>(Hook<R> hook) {
    if (_cursor < 0) {
      throw StateError('Hooks are only available inside Node.build.');
    }

    final hooks = _hooks ??= [];
    if (_cursor == hooks.length) return _append(hook);

    final state = hooks[_cursor];
    final previous = state.hook;

    if (previous.runtimeType != hook.runtimeType) {
      if (_cause != BuildCause.reload) {
        throw StateError(
          'Hook shape changed without a hot reload: slot $_cursor held a '
          '${previous.runtimeType} and now holds a ${hook.runtimeType}. '
          'Hooks must be used unconditionally, in the same order every pass.',
        );
      }

      // The reload edited build() itself, so everything from here on is a
      // fresh declaration and the old states have nothing left to describe.
      _disposeFrom(_cursor);
      return _append(hook);
    }

    if (Hook.shouldPreserveState(previous, hook)) {
      state._hook = hook;
      state.didUpdateHook(previous);
    } else {
      _dispose(state);

      hooks[_cursor] = hook.createState()
        .._node = this
        .._hook = hook
        ..initHook();
    }

    final value = hooks[_cursor].build() as R;
    _cursor += 1;
    return value;
  }

  R _append<R>(Hook<R> hook) {
    final state = hook.createState()
      .._node = this
      .._hook = hook
      ..initHook();

    _hooks!.add(state);
    _cursor += 1;
    return state.build();
  }

  /// Runs one [build] pass, then discards whatever the pass left behind.
  ///
  /// Guarded, and the only guarded path in the engine: a node being edited
  /// throws routinely, and one bad node must not take the walk down with it.
  void _rebuild(BuildCause cause) {
    _ticks?.clear();
    final previous = _cause;
    _cause = cause;
    _cursor = 0;

    try {
      build();
    } catch (exception, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'ignis',
          context: ErrorDescription('while building $runtimeType'),
        ),
      );
    } finally {
      _disposeFrom(_cursor);
      _cursor = -1;
      _cause = previous;
    }
  }

  /// Disposes every hook state from [index] on, in reverse order, and drops
  /// them from the slots.
  void _disposeFrom(int index) {
    final hooks = _hooks;
    if (hooks == null || index >= hooks.length) return;

    for (var i = hooks.length - 1; i >= index; i -= 1) {
      _dispose(hooks[i]);
    }

    hooks.removeRange(index, hooks.length);
  }

  void _dispose(HookState<Object?, Hook<Object?>> state) {
    try {
      state.dispose();
    } catch (exception, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'ignis',
          context: ErrorDescription('while disposing a ${state.runtimeType}'),
        ),
      );
    }
  }

  /// Registers [tick] to run every frame until the next [build] pass.
  ///
  /// Cleared at the top of every pass, so a hook that wants to keep ticking
  /// registers again from its [HookState.build].
  void _addTick(void Function(double dt) tick) {
    (_ticks ??= []).add(tick);
  }

  // #endregion

  // #region Standard Hooks

  /// Runs [effect] now, and again on every later pass.
  ///
  /// Whatever [effect] returns is called before the next run and once more at
  /// teardown, so an effect cleans up after itself:
  ///
  /// ```dart
  /// fuseEffect(() => painter.dispose);
  /// ```
  ///
  /// Re-running is the point. The closure handed in was built by the pass that
  /// runs it, so after a hot reload it is the edited code running, and the
  /// code it replaced has already been cleaned up.
  ///
  /// Pass [keys] to opt out: the effect then re-runs only when they stop
  /// comparing equal, and an empty list means it runs exactly once.
  @nonVirtual
  void fuseEffect(
    Cleanup? Function() effect, [
    List<Object?>? keys,
  ]) {
    fuse(_EffectHook(effect, keys: keys));
  }

  /// Calls [tick] with the elapsed seconds on every frame, for as long as this
  /// node keeps declaring it.
  ///
  /// The alternative to overriding [Node.tick], and the reloadable one: the
  /// closure is registered afresh by every pass, so an edited body is running
  /// the frame after the save.
  ///
  /// ```dart
  /// fuseTick((dt) => shape.angle += _SPIN * dt);
  /// ```
  @nonVirtual
  void fuseTick(void Function(double dt) tick) => fuse(_TickHook(tick));

  /// Builds a child with [create], adds it, and returns the same one on every
  /// later pass.
  ///
  /// ```dart
  /// final shape = fuseChild(() => ShapeNode(shape: .square(100)));
  /// ```
  ///
  /// The child is built once and kept, so its constructor arguments are state
  /// and a reload leaves them alone. Pass [keys] to tie it to something: when
  /// they stop comparing equal the child is removed and a new one built.
  ///
  /// The child is removed when this node unmounts, or when the pass that
  /// declared it stops doing so. Like every tree operation on a mounted node,
  /// both are enqueued rather than immediate.
  @nonVirtual
  T fuseChild<T extends Node>(
    T Function() create, [
    List<Object?> keys = const [],
  ]) {
    return fuse(_ChildHook<T>(create, keys: keys));
  }

  /// Calls [handler] whenever [signal] is emitted.
  ///
  /// The only way a node subscribes to anything, and deliberately so: the
  /// handler is unsubscribed and resubscribed by every pass, so it cannot
  /// outlive this node and cannot keep running code you already edited.
  @nonVirtual
  void fuseSignal0(Signal0 signal, void Function() handler) {
    fuseEffect(() => signal(handler));
  }

  /// Calls [handler] whenever [signal] is emitted. See [fuseSignal0].
  @nonVirtual
  void fuseSignal1<A>(Signal1<A> signal, void Function(A) handler) {
    fuseEffect(() => signal(handler));
  }

  /// Calls [handler] whenever [signal] is emitted. See [fuseSignal0].
  @nonVirtual
  void fuseSignal2<A, B>(Signal2<A, B> signal, void Function(A, B) handler) {
    fuseEffect(() => signal(handler));
  }

  /// Calls [handler] whenever [signal] is emitted. See [fuseSignal0].
  @nonVirtual
  void fuseSignal3<A, B, C>(Signal3<A, B, C> signal, void Function(A, B, C) handler) {
    fuseEffect(() => signal(handler));
  }

  // #endregion

  // #region Attachment

  /// Adds [node] to this node. The node is returned.
  ///
  /// Nodes cannot be added to themselves or their descendants. Adding a child
  /// to its current parent is a no-op.
  T add<T extends Node>(T node) {
    if (owns(node)) {
      return node;
    }

    if (identical(this, node)) {
      throw StateError('Cannot add a node to itself.');
    }

    if (node.hasParent || node._pendingParent != null) {
      // TODO: Why not? Isn't this just a reparenting operation?
      throw StateError('Cannot add a node that already has a parent.');
    }

    if (cycles(node)) {
      throw StateError('Cannot add a node to its descendant.');
    }

    if (isMounted) {
      node._pendingParent = this;
      scene._tree._add(node, this);
    } else {
      _own(node);
    }

    return node;
  }

  /// Adds all [nodes] to this node.
  void addAll(Iterable<Node> nodes) => nodes.forEach(add);

  /// Adds this node to the target [node].
  void attach(Node node) => node.add(this);

  // #endregion

  // #region Detachment

  /// Removes the child [node].
  ///
  /// Returns true if the node was owned by this node and its removal was
  /// accepted. Removing a parentless node, a node not owned by this node, or a
  /// node already awaiting removal, is a no-op that returns `false`.
  bool remove(Node node) {
    if (node._pendingRemoval) return false; // Already being removed.
    if (!owns(node)) return false; // Not our node, not our problem.

    if (isMounted) {
      node._pendingRemoval = true;
      scene._tree._remove(node, this);
    } else {
      _disown(node);
    }

    return true;
  }

  /// Removes all children.
  void removeAll() {
    Iterable<Node>? children = _egg?.nodes;
    if (children == null || children.isEmpty) return;

    // While mounted, removal is deferred to the next flush, so it's safe to
    // iterate the live list. Otherwise, removal is immediate and would
    // mutate the list out from under this loop, so a snapshot is required.
    if (!isMounted) children = children.toList(growable: false);
    for (final child in children) remove(child);
  }

  /// Removes this node from its parent.
  bool detach() => parent?.remove(this) ?? false;

  // #endregion

  // #region Hit Testing

  /// Finds every enabled node in this subtree whose hit area contains
  /// [point], per [containsPoint], topmost first.
  ///
  /// Children are searched in reverse [priority] order before this node's
  /// own hit area, mirroring reverse paint order.
  ///
  /// Unlike [add], [remove], and [priority], [enabled] takes effect
  /// immediately even on a mounted node. A handler invoked mid-walk that
  /// disables an unvisited node will affect that same walk.
  /// TODO: Should it really do that? Is enabled actually a tree operation?
  @nonVirtual
  Iterable<Node> hitTest(Vector2 point) sync* {
    if (!enabled) return;
    final children = _egg?.nodes;

    if (children != null && children.isNotEmpty) {
      for (final child in children.reversed) {
        yield* child.hitTest(point);
      }
    }

    if (containsPoint(point)) yield this;
  }

  /// Whether this node's hit area contains [point].
  ///
  /// The default implementation always returns false, so plain nodes are
  /// invisible to [hitTest]. Override to opt a node into hit-testing.
  @visibleForOverriding
  bool containsPoint(Vector2 point) => false;

  // #endregion

  // #region Dependency Injection

  Map<Type, dynamic>? _providers;
  Map<Type, dynamic>? _dependencies;

  /// Provides [value] as this node's instance of [T], overwriting any value
  /// previously provided for [T].
  void provide<T>(T value) {
    (_providers ??= {})[T] = value;
  }

  /// Reads the nearest instance of [T] provided by this node or an
  /// ancestor, checking this node first.
  ///
  /// Not reactive: whether it finds a match or not, the result is cached
  /// until the node is unmounted, so a later [provide] call for [T] won't be
  /// picked up until then.
  ///
  /// Throws a [StateError] if this node is not mounted yet, or if no [T] was
  /// ever [provide]d.
  T read<T>() {
    final value = readOrNull<T>();
    if (value != null) return value;
    throw StateError('No provider found for $T.');
  }

  /// Reads the nearest instance of [T] provided by this node or an
  /// ancestor, checking this node first. Returns null if none was provided.
  ///
  /// Not reactive: whether it finds a match or not, the result is cached
  /// until the node is unmounted, so a later [provide] call for [T] won't be
  /// picked up until then.
  ///
  /// Throws a [StateError] if this node is not mounted yet.
  T? readOrNull<T>() {
    final dependencies = _dependencies ??= {};
    if (dependencies.containsKey(T)) return dependencies[T] as T?;

    if (!isMounted) {
      throw StateError('Cannot read $T because this node is not mounted yet.');
    }

    Node? node = this;

    while (node != null) {
      final providers = node._providers;

      if (providers != null && providers.containsKey(T)) {
        return dependencies[T] = providers[T] as T;
      }

      node = node.parent;
    }

    return dependencies[T] = null;
  }

  // #endregion
}
