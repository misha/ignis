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
/// their [build] method. [build] is called every time a node is mounted to
/// a live scene.
///
/// [build] must be safe to run more than once. It tracks every node added and
/// every signal subscribed inside it. When the node is unmounted, the nodes
/// are removed and signals automatically unsubscribed. Other resources that
/// need disposal should be put in the [trash] manually.
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
/// Nodes may be mounted to a [Scene], which drives them with a game loop. When
/// mounted, the scene will propagate through the entire subtree emitting the
/// [onMount] signal on each node, from top to bottom. Unmounting does the
/// reverse, emitting the [onUnmount] signal from the leaves upward.
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

    if (children.isEmpty) return;

    for (final child in children) {
      child.update(dt);
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
    if (children.isEmpty) return;

    for (final child in children) {
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
    if (children.isEmpty) return;

    for (final child in children) {
      if (child.activity.renders) {
        child.debugRender(canvas);
      }
    }
  }

  @internal
  void resize(Vector2 size) {
    onSceneResize.emit(size);
    if (children.isEmpty) return;

    for (final child in children) {
      child.resize(size);
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
  ///   - All [add]ed direct children are removed.
  ///   - All [tick], [draw], and [debugDraw] closures are removed.
  ///   - The [trash] is processed and cleared.
  ///
  /// When using [Live], anything named by [Live.keep] is specifically retained.
  void _rebuild() {
    _builtGeneration = _latestGeneration;
    _discardDeclared();

    // Dropped rather than cleared, so a rebuild from inside an [onUpdate]
    // leaves the list that call is being iterated from intact. Its remaining
    // closures run out the frame; the new build installs its own for the next.
    _ticks = null;
    _draws = null;
    _debugDraws = null;
    _cleanup();
    final saved = _building;
    _building = this;

    try {
      build();
      // TODO: Not a fan of the control flow here. Might need a separate method
      //  to specifically handle the two cases instead.
      if (this case final Live live) live._sweep();
      if (scene.hasSize) onSceneResize.emit(scene.size);
    } finally {
      if (this case final Live live) live._claimed = null;
      _building = saved;
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

  /// Detaches every child the last [build] declared.
  void _discardDeclared() {
    final declared = _declared;
    if (declared == null || declared.isEmpty) return;

    for (var i = declared.length - 1; i >= 0; i -= 1) {
      declared[i].detach();
    }

    declared.clear();
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

  // #region Priority

  int _priority;

  /// This node's order in updating and rendering in its parent.
  ///
  /// The default priority is 0. Children that share a priority are kept in
  /// insertion order, like a queue. Changing the priority of a child maintains
  /// this internal ordering with a stable sorting algorithm.
  int get priority => _priority;

  @nonVirtual
  set priority(int value) {
    _priority = value;
    _scheduler.schedule(Task(() => parent?._children?.reorder(this)));
  }

  // #endregion

  // #region Signals

  /// Emitted when this node is added to a scene.
  final onMount = Signal0();

  /// Emitted when this node is removed from a scene.
  final onUnmount = Signal0();

  /// Emitted when the scene resizes, and once at mount.
  final onSceneResize = Signal1<Vector2>();

  // #endregion

  // #region Children

  _Children? _children;

  /// This node's direct children.
  Iterable<Node> get children => _children?.nodes ?? const [];

  /// This node's direct children of type [T], in [priority] order.
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

  // #region Scene

  Scene? _scene;

  /// True while this node is the root of a scene.
  bool get isRoot => identical(_scene?.root, this);

  /// True while this node is part of a scene.
  bool get isMounted => _scene != null;

  /// This node's current scene. Only valid while [isMounted].
  Scene get scene {
    final owner = _scene;
    assert(owner != null, 'This node is not mounted yet.');
    return owner!;
  }

  /// The scheduler used to execute structural changes on the current scene.
  Scheduler get _scheduler {
    if (isMounted) return scene.scheduler;
    return const ImmediateScheduler();
  }

  /// Mounts this node as the root of a new [Scene] and returns it.
  ///
  /// If this is already the root of a scene, returns that same scene.
  Scene mount() {
    if (isRoot) {
      return scene;
    }

    if (_attachment is! _Detached) {
      throw StateError('Cannot mount a node that has a parent.');
    }

    final created = Scene(root: this);
    _mount(created);
    return created;
  }

  @internal
  void unmount() {
    _unmount();
  }

  void _mount(Scene scene) {
    _scene = scene;
    _rebuild();
    final targets = _targets;

    if (targets != null) {
      for (final target in targets) {
        target._resolve();
      }
    }

    onMount.emit();
    final children = _children?.nodes;
    if (children == null) return;

    for (final child in children.toList(growable: false)) {
      if (!identical(child.parent, this)) continue;
      child._mount(scene);
    }
  }

  void _unmount() {
    final children = _children?.nodes;

    if (children != null) {
      for (var i = children.length - 1; i >= 0; i -= 1) {
        children[i]._unmount();
      }
    }

    try {
      onUnmount.emit();
      _cleanup();
      _ticks = null;
      _draws = null;
      _debugDraws = null;
      _discardDeclared();
      _dropAncestry();
    } finally {
      _scene = null;
    }
  }

  // #endregion

  // #region Attachment

  _Attachment _attachment = const _Detached();

  /// True while this node awaits removal at the next flush.
  bool get isRemoving => _attachment is _Removing;

  /// The parent that owns this node, or null when it is parentless.
  Node? get parent => _attachment.parent;

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

  /// Checks if this node owns the [other] node.
  bool owns(Node other) => identical(this, other.parent);

  /// True if [node] is (or soon will be) an ancestor of this node.
  bool cycles(Node node) {
    Node? current = this;

    while (current != null) {
      if (identical(current, node)) return true;
      final attachment = current._attachment;
      current = attachment.destination ?? attachment.parent;
    }

    return false;
  }

  /// Adds [node] to this node. The node is returned.
  ///
  /// Nodes cannot be added to themselves or their descendants. Adding a child
  /// to its current parent is a no-op. If the child was pending removal, this
  /// operation cancels that removal.
  ///
  /// Called from this node's own [build], the child is automatically recorded
  /// as declared, so the next [build] discards it before running again.
  T add<T extends Node>(T node) {
    if (identical(this, node)) {
      throw StateError('Cannot add a node to itself.');
    }

    if (cycles(node)) {
      throw StateError('Cannot add a node to its descendant.');
    }

    if (identical(_building, this)) {
      (_declared ??= []).add(node);
    }

    final attachment = node._attachment;

    if (identical(attachment.destination, this)) {
      return node;
    }

    attachment.task?.cancel();

    if (identical(attachment.parent, this)) {
      node._attachment = _Attached(this);
      return node;
    }

    if (node.isRoot) {
      throw StateError('Cannot add a scene root to another node.');
    }

    final task = Task(() => _attach(node));

    node._attachment = switch (attachment) {
      _Detached() || _Arriving() => _Arriving(this, task),
      _Attached(:final parent) ||
      _Moving(:final parent) ||
      _Removing(:final parent) => _Moving(parent, this, task),
    };

    _scheduler.schedule(task);
    return node;
  }

  /// Adds all [nodes] to this node.
  void addAll(Iterable<Node> nodes) => nodes.forEach(add);

  /// Adds this node to the target [node].
  void attach(Node node) => node.add(this);

  void _attach(Node node) {
    final from = node.parent;

    if (from != null) {
      from._children?.remove(node);
      node._forgetAncestry();
    }

    (_children ??= _Children()).add(node);
    node._attachment = _Attached(this);
    final scene = _scene;

    // A node moved here from another scene leaves that one first. One moved
    // within this scene is already standing, and must not be rebuilt.
    if (identical(node._scene, scene)) return;
    if (node.isMounted) node._unmount();
    if (scene != null) node._mount(scene);
  }

  /// Removes the child [node].
  ///
  /// Returns true if the node was owned by this node and its removal was
  /// accepted. Removing a parentless node, a node not owned by this node, or a
  /// node already awaiting removal, is a no-op that returns `false`.
  ///
  /// A node still awaiting its own addition is cancelled outright, so an add
  /// and a remove queued in the same frame settle to nothing.
  bool remove(Node node) {
    final attachment = node._attachment;
    if (!identical(attachment.destination, this)) return false;
    attachment.task?.cancel();

    switch (attachment) {
      case _Attached():
        _detach(node);

      case _Arriving():
        node._attachment = const _Detached();

      case _Moving(:final parent):
        parent._detach(node);

      case _Detached() || _Removing():
        return false;
    }

    return true;
  }

  /// Removes all children.
  void removeAll() {
    final children = _children?.nodes;
    if (children == null) return;

    for (var i = children.length - 1; i >= 0; i -= 1) {
      remove(children[i]);
    }
  }

  /// Removes this node from its parent, or from the parent it is on its way to.
  bool detach() {
    final attachment = _attachment;
    return (attachment.destination ?? attachment.parent)?.remove(this) ?? false;
  }

  void _detach(Node node) {
    final task = Task(() {
      try {
        if (node.isMounted) node._unmount();
      } finally {
        _children?.remove(node);
        node._attachment = const _Detached();
      }
    });

    node._attachment = _Removing(this, task);
    node._scheduler.schedule(task);
  }

  // #endregion

  // #region Reassembly

  @internal
  void reassemble() {
    _latestGeneration += 1;
    _reassemble();
  }

  void _reassemble() {
    // Already built by the flush that mounted it, against this same code.
    if (this is Live && _builtGeneration != _latestGeneration) {
      // A mid-edit build throws, and must not take the rest of the walk down.
      try {
        _rebuild();
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

    // Settle what the pass just declared, so the walk descends into the tree
    // as it now stands rather than as it stood before the rebuild.
    _scheduler.flush();
    if (children.isEmpty) return;

    for (final child in children.toList(growable: false)) {
      // A rebuild above queued this one's removal, so it is already gone. Its
      // replacement built against the current code and is not in this list.
      if (child.isRemoving) continue;
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
    final children = _children?.nodes;

    if (children != null) {
      for (var i = children.length - 1; i >= 0; i -= 1) {
        yield* children[i].traverse(prune: prune);
      }
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
