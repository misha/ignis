// SPDX-AI-Disclosure: none

part of 'core.dart';

/// Advances a node by the seconds elapsed since the last frame.
typedef Tick = void Function(double dt);

/// Paints a node to the canvas, in its own coordinate space.
typedef Draw = void Function(Canvas canvas);

/// Paints a node's debug overlay, in the same space as a [Draw].
typedef DebugDraw = void Function(Canvas canvas);

/// Call to undo whatever was set up.
typedef Cleanup = void Function();

/// **Overview**
///
/// Nodes are the building block of Ignis. They are organized in a directed,
/// acyclic tree, with [children] ordered by [priority]. Nodes may be assembled
/// into subtrees using [add] and [remove] any number of times.
///
/// **Building**
///
/// Nodes should initialize children, connect signals, and compose behavior in
/// their [build] method. [build] is called every time a node is mounted to a
/// live scene.
///
/// [build] must be safe to run more than once. It tracks every node added and
/// every signal subscribed inside it. When the node is unmounted, the nodes
/// are removed and signals automatically unsubscribed. Other resources that
/// need disposal should be placed in the [trash] manually.
///
/// **Do not make [build] `async`.**
///
/// **Signals**
///
/// Nodes communicate time-sensitive events through signals: named, type-safe
/// message emitters. Use one to report an event to consumers, or as an input
/// to react to external events.
///
/// Conventionally, signals are prefixed with the word `on`. For example, the
/// signal a collider emits on contact is named `onCollisionStart`. This allows
/// consumers to have a natural-reading constructor, e.g.
/// `onCollisionStart(/* do stuff */);`.
///
/// **Scenes**
///
/// Nodes may be mounted to a [Scene], which drives them with a game loop.
///
/// **Tree**
///
/// A node is also a tree. You can [add] and [remove] child nodes, as well as
/// set [priority] to control its order within the list of children.
///
/// Changes to the tree take effect immediately.
///
/// *However*, in-progress updates are a little more complicated. There is no
/// correct answer here. How *should* an update respond if a node is moved?
///
/// The policy for this implementation is: "best effort". If a node is added,
/// removed, or repositioned under a parent the traversal has yet to reach, then
/// the in-progress traversal *will* see the change. Otherwise, the change is
/// processed from the next frame.
///
/// **Dependency Injection**
///
/// Nodes come integrated with a type-based dependency injection (DI) system.
/// A node may [provide] a value to its entire subtree, keyed by its type.
/// [read] resolves the nearest match, checking the node itself before its
/// [ancestors].
///
/// **Reassembly**
///
/// By default nothing in particular happens when the code reassembles. You can
/// change this by opting into the [Live] mixin.
///
/// With [Live], a reassembly completely rebuilds the node. Even disabled nodes
/// are rebuilt. Anything kept with [Live.keep] is retained from the last build.
/// See [Live] for more detailed usage examples.
class Node {
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

  /// Updates this node and its children by [dt] seconds.
  @nonVirtual
  void update(double dt) {
    if (!activity.updates) return;
    final ticks = _ticks;

    if (ticks != null) {
      for (var i = 0; i < ticks.length; i += 1) {
        ticks[i](dt);
      }
    }

    final children = _children?.share();
    if (children == null) return;

    for (var i = 0; i < children.length; i += 1) {
      children[i].update(dt);
    }
  }

  /// Renders this node and its children to [canvas].
  void render(Canvas canvas) {
    renderSelf(canvas);
    renderChildren(canvas);
  }

  /// Runs this node's [draw] callbacks.
  @protected
  void renderSelf(Canvas canvas) {
    final draws = _draws;
    if (draws == null) return;

    for (var i = 0; i < draws.length; i += 1) {
      draws[i](canvas);
    }
  }

  /// Renders this node's enabled children to [canvas], in [priority] order.
  @protected
  void renderChildren(Canvas canvas) {
    final children = _children?.share();
    if (children == null) return;

    for (var i = 0; i < children.length; i += 1) {
      final child = children[i];

      if (child.activity.renders) {
        child.render(canvas);
      }
    }
  }

  /// Renders the debug overlay for this node and its children to [canvas].
  void debugRender(Canvas canvas) {
    debugRenderSelf(canvas);
    debugRenderChildren(canvas);
  }

  /// Runs this node's [debugDraw] callbacks, in the same space as [renderSelf].
  @protected
  void debugRenderSelf(Canvas canvas) {
    final debugDraws = _debugDraws;
    if (debugDraws == null) return;

    for (var i = 0; i < debugDraws.length; i += 1) {
      debugDraws[i](canvas);
    }
  }

  @protected
  void debugRenderChildren(Canvas canvas) {
    final children = _children?.share();
    if (children == null) return;

    for (var i = 0; i < children.length; i += 1) {
      final child = children[i];

      if (child.activity.renders) {
        child.debugRender(canvas);
      }
    }
  }

  // #region Building

  /// Which reassembly is running, bumped once per [Scene.reassemble].
  ///
  /// A node records the pass it last built in, so a subtree the walk mounts on
  /// its way down is not built a second time when the walk reaches it.
  static int _latestGeneration = 0;

  /// The last built generation, which generally lags behind [_latestGeneration].
  int _builtGeneration = -1;

  /// The node whose [build] is currently running, or null between builds.
  static Node? _building;

  /// Runs [body] with [node] as the node building, restoring the previous one
  /// afterward.
  static T _construct<T>(Node? node, T Function() body) {
    final saved = _building;
    _building = node;

    try {
      return body();
    } finally {
      _building = saved;
    }
  }

  // The following fields belong to a single, logical run of `Node.build`. When
  // the node is unmounted or rebuilt, they are processed and/or dropped.

  List<Tick>? _ticks;
  List<Draw>? _draws;
  List<DebugDraw>? _debugDraws;
  List<Cleanup>? _cleanups;

  /// Declares this node's children and behavior.
  ///
  /// Runs every time the node is mounted to a scene. Declared nodes, signals,
  /// and other [trash]ed resources are cleaned up when unmounted.
  @mustCallSuper
  @visibleForOverriding
  void build() {}

  /// Re-derives this node by running [build] again from scratch.
  ///
  /// Everything the previous [build] made is thrown away:
  ///
  ///   - All [add]ed direct children it does not add again are removed.
  ///   - All [tick], [draw], and [debugDraw] closures are removed.
  ///   - The [trash] is processed and cleared.
  @internal
  void rebuild() {
    _builtGeneration = _latestGeneration;

    // Dropped rather than cleared, so a rebuild from inside an [onUpdate]
    // leaves the list that call is being iterated from intact. Its remaining
    // closures run out the frame; the new build installs its own for the next.
    _ticks = null;
    _draws = null;
    _debugDraws = null;
    _cleanup();
    final previouslyDeclared = _declared;
    _declared = null;

    try {
      _construct(this, build);
    } finally {
      _discard(previouslyDeclared);
    }
  }

  /// The children this node's [build] added, in declaration order.
  ///
  /// Separate from [children], which also holds whatever was added imperatively.
  ///
  /// TODO: There's insufficient documentation regarding "declaration" of nodes.
  ///   Honestly, it seems like a new core API, e.g. `declare(child)` causes the
  ///   node to then get automatically removed on rebuild. Such an API would
  ///   even allow (potentially) currently imperative-only additions to *also*
  ///   clean up automatically (like you can remove missiles or whatever if you
  ///   want to clean them up on a code change, when that unit changes).
  List<Node>? _declared;

  /// Removes every child in [previouslyDeclared] that the current list of
  /// declared nodes lacks.
  ///
  /// A child declared again stays put rather than being removed and added back,
  /// so it is not unmounted and remounted along the way.
  void _discard(List<Node>? previouslyDeclared) {
    if (previouslyDeclared == null || previouslyDeclared.isEmpty) return;
    final current = _declared;

    for (var i = previouslyDeclared.length - 1; i >= 0; i -= 1) {
      final child = previouslyDeclared[i];
      if (current != null && current.contains(child)) continue;
      remove(child);
    }
  }

  /// Calls [tick] with the elapsed seconds on every frame.
  ///
  /// ```dart
  /// tick((dt) {
  ///   turret.angle += pi / 4 * dt;
  /// });
  /// ```
  ///
  /// Discarded by the next [build]. Only valid inside this node's own [build].
  @nonVirtual
  void tick(Tick tick) {
    assert(
      identical(_building, this),
      'tick() is only available inside this node\'s own build.',
    );

    (_ticks ??= []).add(tick);
  }

  /// Draws to [canvas] every frame, in this node's own coordinate space.
  ///
  /// ```dart
  /// draw((canvas) {
  ///   canvas.drawCircle(.zero, radius, paint);
  /// });
  /// ```
  ///
  /// Discarded by the next [build]. Only valid inside this node's own [build].
  @nonVirtual
  void draw(Draw draw) {
    assert(
      identical(_building, this),
      'draw() is only available inside this node\'s own build.',
    );

    (_draws ??= []).add(draw);
  }

  /// Draws to the debug overlay every frame, in the same space as [draw].
  ///
  /// Discarded by the next [build]. Only valid inside this node's own [build].
  @nonVirtual
  void debugDraw(DebugDraw draw) {
    assert(
      identical(_building, this),
      'debugDraw() is only available inside this node\'s own build.',
    );

    (_debugDraws ??= []).add(draw);
  }

  /// Defers [cleanup] until this [build] stops being current.
  ///
  /// The trash is emptied right before every rebuild and once at unmount, so
  /// each build cleans up after the one it replaced:
  ///
  /// ```dart
  /// painter = TextPainter(text: span);
  /// trash(painter.dispose);
  /// ```
  ///
  /// Emptied first-in-last-out. Only valid inside this node's own [build].
  @nonVirtual
  void trash(Cleanup cleanup) {
    assert(
      identical(_building, this),
      'trash() is only available inside this node\'s own build.',
    );

    (_cleanups ??= []).add(cleanup);
  }

  void _cleanup() {
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

  // #endregion

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

  Cow<Node>? _children;

  /// This node's children, in [priority] order.
  Iterable<Node> get children => _children ?? const [];

  /// This node's children, in reverse [priority] order.
  Iterable<Node> get reverseChildren => _children?.reversed ?? const [];

  /// This node's children of type [T], in [priority] order.
  ///
  /// The returned object is a live, read-only view of all [T] children.
  Iterable<T> query<T extends Node>() => (_children ??= .new()).query<T>();

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

  /// This node's order in updating and rendering in its parent.
  ///
  /// The default priority is 0. Children that share a priority are kept in
  /// insertion order, like a queue. Changing the priority of a child maintains
  /// this internal ordering with a stable sorting algorithm.
  int get priority => _priority;

  @nonVirtual
  set priority(int nextPriority) {
    if (nextPriority == _priority) return;
    _priority = nextPriority;
    final parent = _parent;
    if (parent == null) return;
    parent._children!.remove(this);
    parent._insert(this);
  }

  // #endregion

  // #region Scene

  Scene? _scene;
  bool _unmounting = false;

  /// True while this node is the root of a scene.
  bool get isRoot => identical(_scene?.root, this);

  /// True while this node is part of a scene.
  bool get isMounted => _scene != null;

  /// True if this node is in the process of unmounting.
  bool get isUnmounting => _unmounting;

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

    _assemble();
  }

  void _assemble() {
    try {
      rebuild();
    } finally {
      for (final child in children) {
        // A child's mount might have detached this node.
        if (!isMounted) {
          break;
        }

        if (owns(child) && !child.isMounted) {
          child._mount(scene);
        }
      }
    }
  }

  void _unmount() {
    if (!isMounted || isUnmounting) return;
    _unmounting = true;
    final children = _children;

    if (children != null) {
      for (final child in children.reversed) {
        if (owns(child)) {
          child._unmount();
        }
      }
    }

    try {
      _cleanup();
      _ticks = null;
      _draws = null;
      _debugDraws = null;
      final declared = _declared;
      _declared = null;
      _discard(declared);
      _dropAncestry();
    } finally {
      _scene = null;
      _unmounting = false;
    }
  }

  // #endregion

  // #region Tree

  Node? _parent;

  /// The parent that owns this node, if any.
  Node? get parent => _parent;

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

  /// True if [node] is this node or one of its ancestors.
  bool cycles(Node node) {
    Node? current = this;

    while (current != null) {
      if (identical(current, node)) return true;
      current = current.parent;
    }

    return false;
  }

  /// Adds [node] to this node. The node is returned.
  ///
  /// Nodes cannot be added to themselves or their descendants, and a node that
  /// is unmounting cannot be added anywhere. Adding a child to its current
  /// parent is a no-op.
  ///
  /// Called from this node's own [build], the child is automatically recorded
  /// as declared, so the next [build] discards it unless it adds it again.
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

    if (isMounted && node.isMounted && !identical(scene, node.scene)) {
      throw StateError('Cannot move a node between two live scenes.');
    }

    if (node.isUnmounting) {
      throw StateError('Cannot add a node while it is unmounting.');
    }

    if (identical(_building, this)) {
      (_declared ??= []).add(node);
    }

    if (identical(node._parent, this)) {
      return node;
    }

    node._reparent(this);
    return node;
  }

  /// Adds all [nodes] to this node.
  void addAll(Iterable<Node> nodes) => nodes.forEach(add);

  /// Adds this node to the target [node].
  void attach(Node node) => node.add(this);

  /// Removes the child [node].
  ///
  /// Returns true if the node was owned by this node and is now removed.
  /// Removing a node not owned by this node is a no-op that returns `false`.
  bool remove(Node node) {
    if (!identical(node._parent, this)) {
      return false;
    }

    node._reparent(null);
    return true;
  }

  /// Removes all children.
  void removeAll() {
    for (final child in reverseChildren) {
      remove(child);
    }
  }

  /// Removes this node from its parent.
  bool detach() => parent?.remove(this) ?? false;

  void _reparent(Node? nextParent) {
    // TODO: It is unclear whether it is "correct" to rebuild a node when
    //  moving it to a new parent in the same scene. However, I have no games
    //  that move nodes, and Flame does not have rebuildable nodes, so there is
    //  literally no point of reference. Revisit this operation when there is
    //  finally a game that depends on moving nodes in some way.
    //
    // TODO: rebuilding is what makes it valid for a node moved mid-update to
    //  update again under a parent the pass has yet to reach, so a moved node
    //  may update twice in one frame.

    try {
      _unmount();
    } finally {
      parent?._children?.remove(this);
      nextParent?._insert(this);
      _parent = nextParent;
      _forgetAncestry();

      // TODO: Revisit this spaghetti.
      if (nextParent != null &&
          nextParent.isMounted &&
          !nextParent.isUnmounting &&
          !identical(_building, nextParent)) {
        _mount(nextParent.scene);
      }
    }
  }

  /// Inserts [child] after every child of equal or lower [priority].
  ///
  /// Ties maintain insertion order.
  void _insert(Node child) {
    final children = _children ??= .new();
    var index = children.length;

    while (index > 0 && children[index - 1]._priority > child._priority) {
      index -= 1;
    }

    children.insert(index, child);
  }

  // #endregion

  // #region Reassembly

  @internal
  void reassemble() {
    _latestGeneration += 1;
    _reassemble();
  }

  void _reassemble() {
    // Already built by the mount that brought it in, against this same code.
    if (this is Live && _builtGeneration != _latestGeneration) {
      // A mid-edit build throws, and must not take the rest of the walk down.
      try {
        _assemble();
      } catch (exception, stack) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: exception,
            stack: stack,
            library: 'ignis',
            context: ErrorDescription('while reassembling $runtimeType'),
          ),
        );
      }
    }

    final children = _children;
    if (children == null) return;

    for (final child in children) {
      // A rebuild above removed this one, and its replacement, if any, already
      // built against the current code.
      if (!child.isMounted) continue;
      child._reassemble();
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
    final children = _children;
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

    if (_parent != null) {
      throw StateError('Cannot mount a node that has a parent.');
    }

    final created = Scene<T>(root: this);
    _mount(created);
    return created;
  }
}
