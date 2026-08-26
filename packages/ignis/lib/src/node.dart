// SPDX-AI-Disclosure: ai-assisted

part of 'core.dart';

/// Advances a node by the seconds elapsed since the last frame.
typedef Tick = void Function(double dt);

/// Paints a node to the canvas, in its own coordinate space.
typedef Draw = void Function(Canvas canvas);

/// Paints a node's debug overlay, in the same space as a [Draw].
typedef DebugDraw = void Function(Canvas canvas);

/// Call to undo whatever was set up.
typedef Cleanup = void Function();

/// The humble node.
///
/// **Overview**
///
/// Nodes are the buildings block of Ignis. They are organized in a directed,
/// acyclic tree, with [children] ordered by [priority]. Nodes may be assembled
/// into subtrees using [add] and [remove] any number of times.
///
/// **Building**
///
/// Nodes should initialize children, connect signals, and add [tick] behavior
/// in their [build] method. [build] is called every time a node is mounted to
/// a live scene, or as the root of its own scene with [mount].
///
/// [build] should be written in such a way that it can be run multiple times.
/// To facilitate this, [build] internally tracks every node added and every
/// signal subscribed inside that method call. If you create resources that
/// should be disposed, place it into the [trash] to prevent leaks.
///
/// Lastly, a reload reboots the internals of every node: added children are
/// removed, signals unsubscribed, the [trash] processed, and [build] run
/// again. What survives is the node itself, and whatever it named with [Live.keep].
///
/// **Do not make [build] `async`.** An asynchronous build breaks engine
/// invariants in multiple, devastating ways.
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
/// **Reassembly**
///
/// When code is reloaded, the scene walks the tree rebuilding every node.
/// Unlike [update] and [render], the walk ignores the [enabled] flag, so even
/// disabled nodes are rebuilt. It runs whenever the `SceneWidget` reassembles
/// in the Flutter tree.
///
/// There is nothing to opt into and nothing to override: name what should
/// carry across with [Live.keep], and everything else is made again.
///
/// Each node answers for itself, and the default answer is nothing, so a save
/// leaves a running game exactly as it was.
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

  /// Updates this node and its children by [dt] seconds.
  @nonVirtual
  void update(double dt) {
    if (!_enabled) return;
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
    renderSelf(canvas);
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

  /// Runs this node's [draw] callbacks.
  @protected
  void renderSelf(Canvas canvas) {
    final draws = _draws;
    if (draws == null) return;

    for (var i = 0; i < draws.length; i += 1) {
      draws[i](canvas);
    }
  }

  /// Renders the debug overlay for this node and its children to [canvas].
  void debugRender(Canvas canvas) {
    debugRenderSelf(canvas);
    final children = _egg?.nodes;
    if (children == null || children.isEmpty) return;

    for (final child in children) {
      if (child._enabled) {
        child.debugRender(canvas);
      }
    }
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

  void _resize(Vector2 size) {
    onSceneResize.emit(size);
    final children = _egg?.nodes;
    if (children == null || children.isEmpty) return;

    for (final child in children) {
      child._resize(size);
    }
  }

  // #region Building

  /// The node whose [build] is currently running, or null between builds.
  ///
  /// How a [Signal] subscribed inside a [build] finds the node that owns it.
  static Node? _builder;

  /// Which reassembly is running, bumped once per [Scene.reassemble].
  ///
  /// A node records the pass it last built in, so a subtree the walk mounts on
  /// its way down is not built a second time when the walk reaches it.
  static int _generation = 0;

  int _built = -1;

  /// Declares this node's children and behavior.
  ///
  /// Runs once on mount, and again whenever the code reassembles.
  ///
  /// `super.build()` is required, as skipping it drops whatever the superclass
  /// declared.
  @mustCallSuper
  @visibleForOverriding
  void build() {}

  /// Re-derives this node by running [build] again over the wreckage of the
  /// last one.
  ///
  /// Everything the previous [build] made is thrown away:
  ///
  ///   - All [add]ed direct children are removed.
  ///   - All [tick], [draw], and [debugDraw] closures are removed.
  ///   - The [trash] is processed and cleared.
  ///
  /// Then, [build] runs again from the top, so constructor arguments are
  /// re-evaluated exactly like a statement is. What survives is this node
  /// itself: its members, its position, and anything added to it imperatively.
  ///
  /// A child the new body [add]s back is preserved rather than replaced, as is
  /// everything the body named with [Live.keep].
  ///
  void _rebuild() {
    _built = _generation;
    _discardDeclared();

    // Dropped rather than cleared, so a rebuild from inside an [onUpdate]
    // leaves the list that call is being iterated from intact. Its remaining
    // closures run out the frame; the new build installs its own for the next.
    _ticks = null;
    _draws = null;
    _debugDraws = null;
    _cleanup();
    final builder = _builder;
    _builder = this;

    try {
      build();
      if (this case final Live live) live._sweep();
      final scene = _scene;

      if (scene != null && scene.hasSize) {
        onSceneResize.emit(scene.size);
      }
    } finally {
      if (this case final Live live) live._claimed = null;
      _builder = builder;
    }
  }

  /// The children this node's [build] added, in declaration order.
  ///
  /// Separate from [children], which also holds whatever was added imperatively.
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

  // #endregion

  // #region Ticks

  List<Tick>? _ticks;

  /// Calls [tick] with the elapsed seconds on every frame.
  ///
  /// ```dart
  /// tick((dt) {
  ///   turret.angle += pi / 4 * dt;
  /// });
  /// ```
  @nonVirtual
  void tick(Tick tick) {
    (_ticks ??= []).add(tick);
  }

  // #endregion

  // #region Draws

  List<Draw>? _draws;
  List<DebugDraw>? _debugDraws;

  /// Draws to [canvas] every frame, in this node's own coordinate space.
  ///
  /// ```dart
  /// draw((canvas) {
  ///   canvas.drawCircle(.zero, radius, paint);
  /// });
  /// ```
  @nonVirtual
  void draw(Draw draw) {
    (_draws ??= []).add(draw);
  }

  /// Draws to the debug overlay every frame, in the same space as [draw].
  @nonVirtual
  void debugDraw(DebugDraw draw) {
    (_debugDraws ??= []).add(draw);
  }

  // #endregion

  // #region Trash

  List<Cleanup>? _cleanups;

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
  /// Emptied most-recent-first, so a teardown that emits must be trashed after
  /// the handlers it will notify.
  @nonVirtual
  void trash(Cleanup cleanup) {
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

  // #region Enabled

  bool _enabled;

  /// Whether this node updates, renders, and answers input. Defaults to true.
  bool get enabled => _enabled;

  /// Enables this node, so it resumes updating, rendering and answering.
  @mustCallSuper
  void enable() => _enabled = true;

  /// Disables this node, so it stops updating, rendering and answering.
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

  /// Emitted when this node is added to a scene.
  final onMount = Signal0();

  /// Emitted when this node is removed from a scene.
  final onUnmount = Signal0();

  /// Emitted when the scene resizes, and once at mount.
  final onSceneResize = Signal1<Vector2>();

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
    if (scene == null) return;

    // A node moved here from another scene leaves that one first. One moved
    // within this scene is already standing, and must not be rebuilt.
    if (node.isMounted && !identical(node._scene, scene)) node._unmount();
    node._mount(scene);
  }

  /// Unhooks [node] without unmounting it, so it can stand under a new parent.
  void _release(Node node) {
    _egg?.remove(node);
    node._parent = null;
    node._pendingRemoval = false;
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
    // Already standing here, which is how a moved subtree is left alone.
    if (identical(_scene, scene)) return;
    _scene = scene;
    _rebuild();
    onMount.emit();
    final targets = _targets;

    if (targets != null) {
      for (final target in targets) {
        target._resolve();
      }
    }

    final children = _egg?.nodes;

    if (children != null && children.isNotEmpty) {
      // Snapshotted: a handler is free to move a child to another parent,
      // which takes it out of the list being walked.
      for (final child in children.toList(growable: false)) {
        child._mount(scene);
      }
    }
  }

  void _unmount() {
    // TODO: Assert non-null _scene?
    final children = _egg?.nodes;

    if (children != null && children.isNotEmpty) {
      // Snapshotted, for the same reason as [_mount].
      for (final child in children.toList(growable: false)) {
        child._unmount();
      }
    }

    onUnmount.emit();
    _cleanup();
    _ticks = null;
    _draws = null;
    _debugDraws = null;
    _declared = null;
    _scene = null;
    _dropAncestry();
  }

  // #endregion

  // #region Attachment

  /// Adds [node] to this node. The node is returned.
  ///
  /// Nodes cannot be added to themselves or their descendants. Adding a child
  /// to its current parent is a no-op, and cancels its pending removal, so a
  /// child held on the instance survives the reload that discarded it.
  ///
  /// Called from this node's own [build], the child is additionally recorded
  /// as declared, so the next rebuild discards it before running the body
  /// again. The node handed in is always the node handed back.
  T add<T extends Node>(T node) {
    if (identical(_builder, this)) (_declared ??= []).add(node);

    if (owns(node)) {
      node._pendingRemoval = false;
      return node;
    }

    if (identical(this, node)) {
      throw StateError('Cannot add a node to itself.');
    }

    if (cycles(node)) {
      throw StateError('Cannot add a node to its descendant.');
    }

    // Already somewhere else, so this is a move. Cancel whatever was queued
    // for it there, unhook it without unmounting, and drop the ancestry it
    // had cached.
    node._pendingParent = null;

    if (node.hasParent) {
      node._parent!._release(node);
      node._forgetAncestry();
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
  ///
  /// A node still awaiting its own addition is cancelled outright, so an add
  /// and a remove queued in the same frame settle to nothing.
  bool remove(Node node) {
    if (identical(node._pendingParent, this)) {
      node._pendingParent = null; // Cancels the addition queued this frame.
      return true;
    }

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

  /// Removes this node from its parent, or from the parent it is on its way to.
  bool detach() => (parent ?? _pendingParent)?.remove(this) ?? false;

  // #endregion

  // #region Reassembly

  void _reassemble() {
    // Already built by the flush that mounted it, against this same code.
    if (this is Live && _built != _generation) {
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
    if (isMounted) scene._tree.flush();
    final children = _egg?.nodes;
    if (children == null || children.isEmpty) return;

    for (final child in children.toList(growable: false)) {
      // A rebuild above queued this one's removal, so it is already gone. Its
      // replacement built against the current code and is not in this list.
      if (child._pendingRemoval) continue;
      child._reassemble();
    }
  }

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
  ///
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
  List<Target<Object?>>? _targets;

  /// Registers [target] to be dropped whenever this node's ancestry changes.
  void _track(Target<Object?> target) {
    (_targets ??= []).add(target);
  }

  /// Drops what this node resolved through its ancestors.
  void _dropAncestry() {
    _dependencies = null;
    final targets = _targets;
    if (targets == null) return;

    for (final target in targets) {
      target._invalidate();
    }
  }

  /// Drops the same across this subtree, for a node that just moved.
  void _forgetAncestry() {
    _dropAncestry();
    final children = _egg?.nodes;
    if (children == null || children.isEmpty) return;

    for (final child in children) {
      child._forgetAncestry();
    }
  }

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
