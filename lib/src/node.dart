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
/// live tree. The closures do not survive the re-run, so they come back
/// freshly compiled; anything that should survive is named with [live].
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

  /// Updates this node and its children by [dt] seconds.
  @nonVirtual
  void update(double dt) {
    if (!_enabled) return;
    final updates = _updates;

    if (updates != null) {
      for (var i = 0; i < updates.length; i += 1) {
        updates[i](dt);
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
  /// A node rebuilds only if its [build] is written in one of the [changed]
  /// files, so editing one node restarts that node's subtree and leaves the
  /// rest of the scene running. Pass null to rebuild everything, which is the
  /// right answer whenever the changed set is unknown or covers code no node
  /// claims - a shared constant, a data file, an enum.
  ///
  /// The walk itself always continues, since a child may be declared in a file
  /// its parent is not.
  @nonVirtual
  void reassemble([Set<String>? changed]) {
    if (changed == null || _declaredIn(changed)) _rebuild();

    final children = _egg?.nodes;
    if (children == null || children.isEmpty) return;

    // Snapshotted: a rebuild above may have replaced this list wholesale.
    for (final child in children.toList(growable: false)) {
      if (child.isMounted) child.reassemble(changed);
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

  void _resize(Vector2 size) {
    onSceneResize.emit(size);
    final children = _egg?.nodes;
    if (children == null || children.isEmpty) return;

    for (final child in children) {
      child._resize(size);
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

  /// Emitted when the scene resizes, and again after every [build], so a
  /// handler the pass just installed hears the current size rather than
  /// waiting for a change that already happened.
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
    _rebuild();
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
    _emptyTrash();
    _updates = null;
    _trash = null;
    _declared = null;
    _scene = null;
    _dependencies = null;
  }

  // #endregion

  // #region Building

  /// The node whose [build] pass is currently running, or null between passes.
  ///
  /// How [live] and a [Signal] subscribed mid-pass find the building node.
  static Node? _builder;

  /// Declares this node's children and behavior.
  ///
  /// Runs once on mount, and again in full whenever the code it is written in
  /// changes. A rebuild throws away everything the previous pass made - the
  /// children it added, its [tick] closures, its [trash] - and runs the body
  /// again from the top, so a constructor argument is re-evaluated exactly
  /// like a statement is.
  ///
  /// Nothing is preserved and nothing is matched up, so there are no rules
  /// about where a declaration sits. What survives a rebuild is this node
  /// itself: its fields, its position, and anything added to it imperatively.
  ///
  /// `super.build()` is required: skipping it drops whatever the superclass
  /// declared, and the source tracking that decides when this node reloads.
  @mustCallSuper
  @visibleForOverriding
  void build() {
    assert(_recordSources(), 'unreachable');
  }

  /// Runs one [build] pass, having destroyed whatever the last one made.
  ///
  /// Guarded, and the only guarded path in the engine: a node being edited
  /// throws routinely, and one bad node must not take the walk down with it.
  void _rebuild() {
    _discardDeclared();
    _updates?.clear();
    _emptyTrash();
    final builder = _builder;
    _builder = this;

    try {
      build();

      // The pass installed handlers that have never heard anything. A signal
      // carrying a current value has to say it again, or the rebuilt body is
      // left waiting for a change that already happened.
      final scene = _scene;
      if (scene != null && scene.hasSize) onSceneResize.emit(scene.size);
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
      _builder = builder;
    }
  }

  /// The children this node's [build] added, in declaration order.
  ///
  /// Separate from [children], which also holds whatever was added
  /// imperatively - a runtime spawn is nobody's declaration and must survive
  /// a rebuild that never mentions it.
  List<Node>? _declared;

  /// Detaches every child the last pass declared.
  void _discardDeclared() {
    final declared = _declared;
    if (declared == null || declared.isEmpty) return;

    for (var i = declared.length - 1; i >= 0; i -= 1) {
      declared[i].detach();
    }

    declared.clear();
  }

  // #endregion

  // #region Sources

  /// Where each node type's [build] is written, keyed by that type.
  ///
  /// A type's entry holds every file its build body spans, superclasses
  /// included, so editing a base class reloads the nodes derived from it.
  /// Debug-only: nothing reloads in a release build, so nothing records.
  static final Map<Type, Set<String>> _sources = {};

  static final _frame = RegExp(r'^#\d+\s+(\S+)\s+\((\S+?):\d+:\d+\)$');

  /// The files this node's [build] is written in.
  ///
  /// Empty until an instance of this type has built once, and empty in a
  /// release build, where nothing reloads and so nothing is recorded.
  @visibleForTesting
  Set<String> get sources => _sources[runtimeType] ?? const {};

  /// True if [build] runs in code drawn from any of [changed].
  bool _declaredIn(Set<String> changed) {
    final sources = _sources[runtimeType];
    if (sources == null) return false;

    for (final source in sources) {
      if (changed.contains(source)) return true;
    }

    return false;
  }

  /// Records the files this node's [build] is written in, the first time an
  /// instance of its type builds.
  ///
  /// The stack is the index: every `*.build` frame below this one belongs to
  /// a class in the chain, and carries the file it was compiled from. Called
  /// from inside an [assert] so it costs a release build nothing.
  bool _recordSources() {
    final type = runtimeType;
    if (_sources.containsKey(type)) return true;
    final sources = _sources[type] = {};

    for (final line in StackTrace.current.toString().split('\n')) {
      final match = _frame.firstMatch(line.trim());
      if (match == null) continue;
      final member = match.group(1)!;
      if (!member.endsWith('.build')) continue;
      sources.add(match.group(2)!);
    }

    return true;
  }

  // #endregion

  // #region Updates

  List<void Function(double dt)>? _updates;

  /// Calls [update] with the elapsed seconds on every frame, for as long as
  /// this node keeps declaring it.
  ///
  /// The only way a node runs per-frame code, and it reloads: the closure is
  /// registered afresh by every pass, so an edited body is running the frame
  /// after the save. Write it inline - the whole point is that the behavior
  /// reads at the site it is declared.
  ///
  /// ```dart
  /// onUpdate((dt) {
  ///   square.angle += _SPIN * dt;
  /// });
  /// ```
  ///
  /// The list is cleared and refilled by every pass, so this may be called
  /// from inside an `if`, a loop, or a helper.
  @nonVirtual
  void onUpdate(void Function(double dt) update) {
    (_updates ??= []).add(update);
  }

  // #endregion

  // #region Trash

  List<Cleanup>? _trash;

  /// Whatever this [build] pass has to release when it stops being current.
  ///
  /// The bag is emptied right before every pass and once at unmount, so a
  /// pass cleans up after the one it replaced:
  ///
  /// ```dart
  /// painter = TextPainter(text: span);
  /// trash << painter.dispose;
  /// ```
  ///
  /// The bag is an extension type over this node, so a node that never defers
  /// anything holds a null rather than an object.
  @nonVirtual
  Trash get trash => Trash(this);

  /// Runs every deferred cleanup, most recently thrown in first.
  ///
  /// Guarded: one bad cleanup must not strand the rest of the bag. The list is
  /// taken first, so a cleanup that defers more work fills a fresh bag rather
  /// than one being emptied out from under it.
  void _emptyTrash() {
    final cleanups = _trash;
    if (cleanups == null || cleanups.isEmpty) return;
    _trash = null;

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

  // #region Attachment

  /// Adds [node] to this node. The node is returned.
  ///
  /// Nodes cannot be added to themselves or their descendants. Adding a child
  /// to its current parent is a no-op.
  ///
  /// Called from this node's own [build], the child is additionally recorded
  /// as declared, so the next rebuild destroys it before running the body
  /// again. The node handed in is always the node handed back.
  T add<T extends Node>(T node) {
    if (identical(_builder, this)) (_declared ??= []).add(node);
    return _addNow(node);
  }

  T _addNow<T extends Node>(T node) {
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
  void addAll(Iterable<Node> nodes) {
    for (final node in nodes) {
      add(node);
    }
  }

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
