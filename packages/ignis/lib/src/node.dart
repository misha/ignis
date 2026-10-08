// SPDX-AI-Disclosure: none

part of 'core.dart';

/// **Overview**
///
/// Nodes are the building block of Ignis. They are organized in a directed,
/// acyclic tree, with [children] ordered by [priority]. Nodes are assembled
/// into subtrees using [add] and [remove].
///
/// **Processing**
///
/// Nodes compose behavior in their [process] method. [Build] is processed when
/// a node is mounted to a live scene, and [Destroy] when it is unmounted.
/// Whatever a node sets up under one, it undoes under the other.
///
/// A node lives once. Unmounting destroys it, and a destroyed node can never be
/// added again.
///
/// **Do not make [process] `async`.**
///
/// **Messages**
///
/// Nodes are an [Address] and may [post] messages to one another. Indeed, this is
/// how the entire engine runs. The implementation of [post] simply passes it
/// along to [process] automatically.
///
/// **Scenes**
///
/// Nodes may be mounted to a [Scene], which drives them with a game loop.
///
/// **Tree**
///
/// Before being mounted, the [add], [remove], and [priority] tree operations
/// take effect immediately, allowing a subtree to be freely assembled long
/// before it goes live.
///
/// Once mounted, however, the same calls are instead merely enqueued. The
/// scene applies pending changes right before the next [update]. As a result,
/// operations for live node trees are always delayed a frame. The queue avoids
/// mutation during iteration and batches changes.
///
/// **Dependency Injection**
///
/// Nodes come integrated with a type-based dependency injection (DI) system.
/// A node may [provide] a value to its entire subtree, keyed by its type.
/// [read] resolves the nearest match, checking the node itself before its
/// [ancestors].
class Node with Address {
  /// Creates a new node.
  ///
  /// [activity] sets whether the node ticks, renders, and accepts input.
  /// Defaults to [Activity.all].
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
       activity = (enabled ?? true) ? .all : .none {
    addAll(children);
  }

  /// Executes all this node's behavior for the given [message].
  @visibleForOverriding
  void process(Message message) {
    // Nothing to do.
  }

  /// Processes [message] on this node.
  @override
  @nonVirtual
  void post(Message message) {
    assert(!_destroyed, 'Cannot post ${message.runtimeType} to a destroyed $runtimeType.');
    process(message);
  }

  /// Updates this node and its children by [Update.dt] seconds.
  @nonVirtual
  void update(Update update) {
    if (!activity.updates) return;
    process(update);

    final children = _children?.nodes;
    if (children == null || children.isEmpty) return;

    for (var i = 0; i < children.length; i += 1) {
      children[i].update(update);
    }
  }

  /// Renders this node and its children to [Draw.canvas].
  void render(Draw draw) {
    renderSelf(draw);
    renderChildren(draw);
  }

  /// Processes [Draw] for this node.
  @protected
  void renderSelf(Draw draw) {
    process(draw);
  }

  /// Renders this node's enabled children to [Draw.canvas], in [priority] order.
  @protected
  void renderChildren(Draw draw) {
    final children = _children?.nodes;
    if (children == null || children.isEmpty) return;

    for (var i = 0; i < children.length; i += 1) {
      final child = children[i];

      if (child.activity.renders) {
        child.render(draw);
      }
    }
  }

  /// Renders the debug overlay for this node and its children to [DebugDraw.canvas].
  void debugRender(DebugDraw draw) {
    debugRenderSelf(draw);
    debugRenderChildren(draw);
  }

  /// Processes [DebugDraw] for this node, in the same space as [renderSelf].
  @protected
  void debugRenderSelf(DebugDraw draw) {
    process(draw);
  }

  @protected
  void debugRenderChildren(DebugDraw draw) {
    final children = _children?.nodes;
    if (children == null || children.isEmpty) return;

    for (var i = 0; i < children.length; i += 1) {
      final child = children[i];

      if (child.activity.renders) {
        child.debugRender(draw);
      }
    }
  }

  // #region Activity

  /// A bitmap indicating what kinds of activity this node responds to.
  ///
  /// Defaults to [Activity.all].
  Activity activity;

  /// Whether this node participates in all activity.
  ///
  /// If even one bit of [activity] is disabled, this is false.
  bool get enabled => activity == .all;

  /// Enables this node.
  @mustCallSuper
  void enable() => activity = .all;

  /// Disables this node.
  @mustCallSuper
  void disable() => activity = .none;

  /// Calls [enable] or [disable] depending on [value].
  @nonVirtual
  set enabled(bool value) {
    if (value) {
      enable();
    } else {
      disable();
    }
  }

  // #endregion

  // #region Children

  _Children? _children;

  /// This node's children, in [priority] order.
  Iterable<Node> get children {
    return _children?.nodes ?? const [];
  }

  /// This node's children, in reverse [priority] order.
  Iterable<Node> get reverseChildren sync* {
    final children = _children?.nodes;
    if (children == null) return;

    for (var i = children.length - 1; i >= 0; i -= 1) {
      yield children[i];
    }
  }

  /// This node's children of type [T], in [priority] order.
  ///
  /// The returned object is a live, read-only view of all [T] children.
  Iterable<T> query<T extends Node>() => (_children ??= _Children()).query<T>();

  /// This node's descendants in depth-first preorder.
  Iterable<Node> get descendants sync* {
    for (final child in children) {
      yield child;
      yield* child.descendants;
    }
  }

  /// Checks if this node contains the [other] node.
  bool contains(Node other) => //
      descendants.any((descendant) => identical(descendant, other));

  // #endregion

  // #region Priority

  int _priority;
  _ReorderTask? _reorderTask;

  /// This node's order in updating and rendering in its parent.
  ///
  /// The default priority is 0. Children that share a priority are kept in
  /// insertion order, like a queue.
  int get priority => _priority;

  /// This node's [priority], or what it is scheduled to be.
  int get incomingPriority => _reorderTask?.priority ?? _priority;

  @nonVirtual
  set priority(int value) => _schedulePriority(value);

  void _schedulePriority(int priority) {
    _reorderTask?.cancel();
    _reorderTask = null;
    if (priority == _priority) return;
    final task = _ReorderTask(this, priority);

    if (isMounted) {
      scene.schedule(task);
      _reorderTask = task;
    } else {
      task.execute();
    }
  }

  void _reorder(int priority) {
    _reorderTask = null;
    _priority = priority;
    _parent?._children?.reorder(this);
  }

  // #endregion

  // #region Scene

  Scene? _scene;

  /// True while this node is the root of a scene.
  bool get isRoot => identical(_scene?.root, this);

  /// True while this node is part of a scene.
  bool get isMounted => _scene != null;

  bool _destroyed = false;

  /// True once this node has been unmounted. A destroyed node is never mounted
  /// again.
  bool get isDestroyed => _destroyed;

  /// This node's current scene. Only valid while [isMounted].
  Scene get scene {
    assert(isMounted, 'This node is not mounted yet.');
    return _scene!;
  }

  @internal
  void unmount() {
    _unmount();
  }

  void _mount(Scene scene) {
    _scene = scene;
    final targets = _targets;

    if (targets != null) {
      for (final target in targets) {
        target._resolve();
      }
    }

    try {
      process(const Build());
    } finally {
      final children = _children?.nodes;

      if (children != null) {
        for (final child in children.toList(growable: false)) {
          if (!identical(child.parent, this)) continue;
          child._mount(scene);
        }
      }
    }
  }

  void _unmount() {
    for (final child in reverseChildren) {
      child._unmount();
    }

    try {
      try {
        process(const Destroy());
      } catch (exception, stack) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: exception,
            stack: stack,
            library: 'ignis',
            context: ErrorDescription('while destroying $runtimeType'),
          ),
        );
      }

      _dropAncestry();
    } finally {
      _scene = null;
      _destroyed = true;
    }
  }

  // #endregion

  // #region Tree

  Node? _parent;
  _ReparentTask? _reparentTask;

  /// The parent that owns this node, if any.
  Node? get parent => _parent;

  /// The [parent] that owns or is scheduled to own this node, if any.
  Node? get incomingParent => _reparentTask != null ? _reparentTask!.parent : parent;

  /// True if this node has a non-null [parent].
  bool get hasParent => parent != null;

  /// Checks if this node owns the [other] node.
  bool owns(Node other) => identical(this, other.parent);

  /// This node's ancestors in the tree.
  Iterable<Node> get ancestors sync* {
    var ancestor = parent;

    while (ancestor != null) {
      yield ancestor;
      ancestor = ancestor.parent;
    }
  }

  /// True if [node] is, or soon will be, an ancestor of this node.
  bool cycles(Node node) {
    Node? current = this;

    while (current != null) {
      if (identical(current, node)) return true;
      current = current.incomingParent;
    }

    return false;
  }

  /// Adds [node] to this node. The node is returned.
  ///
  /// Nodes cannot be added to themselves or their descendants. A mounted or
  /// destroyed node cannot be added either. Until it mounts, adding a node
  /// elsewhere moves it, and adding it to its current parent is a no-op.
  T add<T extends Node>(T node) {
    if (identical(this, node)) {
      throw StateError('Cannot add a node to itself.');
    }

    if (cycles(node)) {
      throw StateError('Cannot add a node to its descendant.');
    }

    if (node.isRoot) {
      throw StateError('Cannot add a scene root to another node.');
    }

    if (node._destroyed) {
      throw StateError('Cannot add a destroyed node.');
    }

    if (node.isMounted) {
      throw StateError('Cannot add a mounted node.');
    }

    if (identical(node.incomingParent, this)) {
      return node;
    }

    node._scheduleParent(this);
    return node;
  }

  /// Adds all [nodes] to this node.
  void addAll(Iterable<Node> nodes) => nodes.forEach(add);

  /// Adds this node to the target [node].
  void attach(Node node) => node.add(this);

  /// Removes the child [node].
  ///
  /// Returns true if the node was owned by this node and its removal was
  /// accepted. Removing a parentless node, a node not owned by this node, or a
  /// node already awaiting removal, is a no-op that returns `false`.
  ///
  /// If the node was scheduled to be added, that operation is cancelled instead.
  bool remove(Node node) {
    if (!identical(node.incomingParent, this)) return false;
    node._scheduleParent(null);
    return true;
  }

  /// Removes all children.
  void removeAll() {
    for (final child in reverseChildren) {
      remove(child);
    }
  }

  /// Removes this node from its parent.
  bool detach() => incomingParent?.remove(this) ?? false;

  void _scheduleParent(Node? parent) {
    _reparentTask?.cancel();
    _reparentTask = null;
    if (identical(parent, _parent)) return;
    final task = _ReparentTask(this, parent);
    final scene = _scene ?? parent?._scene;

    if (scene != null) {
      scene.schedule(task);
      _reparentTask = task;
    } else {
      task.execute();
    }
  }

  void _reparent(Node? nextParent) {
    _reparentTask = null;
    final outgoing = _scene;
    final incoming = nextParent?._scene;

    try {
      if (outgoing != null) _unmount();
    } finally {
      parent?._children?.remove(this);
      (nextParent?._children ??= _Children())?.add(this);
      _parent = nextParent;
      _forgetAncestry();
      if (incoming != null) _mount(incoming);
    }
  }

  // #endregion

  // #region Hit Testing

  /// This node and its subtree, in postorder: every child before its parent,
  /// and children in reverse [priority] order.
  ///
  /// [prune] skips a node and everything beneath it, so a walk can stop at a
  /// subtree rather than filter it out afterwards.
  @nonVirtual
  Iterable<Node> traverse({bool Function(Node node)? prune}) sync* {
    if (prune != null && prune(this)) return;

    for (final child in reverseChildren) {
      yield* child.traverse(prune: prune);
    }

    yield this;
  }

  /// Finds every node in this subtree whose hit area contains [point], per
  /// [containsPoint], topmost first.
  ///
  /// When [Activity.inputs] is disabled, this node and its entire subtree are
  /// excluded from hit testing.
  ///
  /// Unlike [add], [remove], and [priority], [enabled] takes effect
  /// immediately even on a mounted node. A handler invoked mid-walk that
  /// disables an unvisited node will affect that same walk.
  ///
  /// TODO: Should it really do that? Is enabled actually a tree operation?
  @nonVirtual
  Iterable<Node> hitTest(Vector2 point) =>
      // TODO: Controls prune on this same predicate, so "input does not reach
      //  here" is now stated at two call sites rather than once. Decide where
      //  input reachability actually belongs; it is not the traversal's business.
      traverse(prune: ((node) => !node.activity.inputs)) //
          .where((node) => node.containsPoint(point));

  /// Whether this node's hit area contains [point].
  ///
  /// Override to opt into [hitTest]. Plain nodes never match.
  @visibleForOverriding
  bool containsPoint(Vector2 point) => false;

  // #endregion

  // #region Dependency Injection

  Map<Type, dynamic>? _providers;
  Map<Type, dynamic>? _dependencies;
  List<Target<Object?>>? _targets;

  /// Registers [target] to be dropped whenever this node's ancestry changes.
  void _track(Target<Object?> target) {
    (_targets ??= []).add(target);
  }

  /// Drops all registered targets for this node.
  ///
  /// TODO: Really bad naming between this and `_forgetAncestry`. One is shallow
  ///   while the other is deep. Think of something better.
  void _dropAncestry() {
    _dependencies = null;
    final targets = _targets;
    if (targets == null) return;

    for (final target in targets) {
      target._invalidate();
    }
  }

  /// Drops all registered targets for this node and its entire subtree.
  void _forgetAncestry() {
    _dropAncestry();
    final children = _children?.nodes;
    if (children == null) return;

    for (final child in children) {
      child._forgetAncestry();
    }
  }

  /// Provides [value] as this node's instance of [T], overwriting any value
  /// previously provided for [T].
  void provide<T>(T value) {
    (_providers ??= {})[T] = value;
  }

  /// As [readOrNull], but throws a [StateError] when nothing [provide]d [T].
  T read<T>() {
    final value = readOrNull<T>();
    if (value != null) return value;
    throw StateError('No provider found for $T.');
  }

  /// Reads the nearest instance of [T] provided by this node or an
  /// ancestor, checking this node first. Returns null if none was provided.
  ///
  /// Cached until unmount, misses included.
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

/// Mounts a node as the root of a new [Scene].
extension Mount<T extends Node> on T {
  /// Mounts this node as the root of a new [Scene] and returns it.
  ///
  /// If this is already the root of a scene, returns that same scene.
  Scene<T> mount() {
    if (isRoot) {
      final existing = scene;

      if (existing is! Scene<T>) {
        throw StateError('Cannot mount a node under a different root type.');
      }

      return existing;
    }

    if (_destroyed) {
      throw StateError('Cannot mount a destroyed node.');
    }

    if (_parent != null) {
      throw StateError('Cannot mount a node that has a parent.');
    }

    _reparentTask?.cancel();
    _reparentTask = null;
    final created = Scene<T>(root: this);
    _mount(created);
    return created;
  }
}
