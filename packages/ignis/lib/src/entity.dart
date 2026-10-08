part of 'core.dart';

/// **Overview**
///
/// Entities are the building block of Ignis. They are organized in a directed,
/// acyclic tree, with [children] ordered by [priority]. Entities are assembled
/// into subtrees using [add] and [remove].
///
/// An entity is a transform: a [position], [scale], [angle], and [anchor],
/// with a [shape] the anchor is measured against. It holds [components],
/// which carry everything else.
///
/// **Processing**
///
/// Entities compose behavior in their [process] method. [Build] is processed
/// when an entity is mounted to a live scene, and [Destroy] when it is
/// unmounted. Whatever an entity sets up under one, it undoes under the other.
///
/// An entity lives once. Unmounting destroys it, and a destroyed entity can
/// never be added again.
///
/// **Do not make [process] `async`.**
///
/// **Messages**
///
/// Entities are an [Address] and may [post] messages to one another. Indeed,
/// this is how the entire engine runs. The implementation of [post] simply
/// passes it along to [process] automatically. Components post to their entity.
///
/// **Scenes**
///
/// Entities may be mounted to a [Scene], which drives them with a game loop.
///
/// **Tree**
///
/// Before being mounted, the [add], [remove], and [priority] tree operations
/// take effect immediately, allowing a subtree to be freely assembled long
/// before it goes live.
///
/// Once mounted, however, the same calls are instead merely enqueued. The
/// scene applies pending changes right before the next [update]. As a result,
/// operations for live entity trees are always delayed a frame. The queue
/// avoids mutation during iteration and batches changes. Adding and removing
/// [components] follows the same rules.
///
/// **Dependency Injection**
///
/// Entities come integrated with a type-based dependency injection (DI)
/// system. An entity may [provide] a value to its entire subtree, keyed by its
/// type. [read] resolves the nearest match, checking the entity itself before
/// its [ancestors].
class Entity with Address, Geometry implements OpacityOwner {
  /// Whether this entity clips its components and subtree to its [shape].
  /// Defaults to false.
  ///
  /// Hit-testing is not clipped: a child outside the area still answers.
  bool clip;

  /// Creates a new entity.
  ///
  /// [activity] sets whether the entity ticks and renders.
  /// Defaults to [Activity.all].
  ///
  /// [priority] controls this entity's order when updating and rendering.
  /// Defaults to 0.
  ///
  /// If [components] or [children] are provided, they are immediately added to
  /// the entity.
  Entity({
    Shape? shape,
    Vector2? position,
    Vector2? scale,
    double? angle,
    Anchor? anchor,
    double? opacity,
    bool? clip,
    bool? enabled,
    int? priority,
    Iterable<Component> components = const [],
    Iterable<Entity> children = const [],
  }) : clip = clip ?? false,
       _priority = priority ?? 0,
       activity = (enabled ?? true) ? .all : .none {
    if (shape != null) this.shape = shape;
    if (position != null) this.position.setFrom(position);
    if (scale != null) this.scale.setFrom(scale);
    if (angle != null) this.angle = angle;
    if (anchor != null) this.anchor = anchor;

    if (opacity != null) {
      this.opacity = opacity;
    }

    this.components.addAll(components);
    addAll(children);
  }

  /// Executes all this entity's behavior for the given [message].
  @visibleForOverriding
  void process(Message message) {
    // Nothing to do.
  }

  /// Processes [message] on this entity.
  @override
  @nonVirtual
  void post(Message message) {
    assert(!_destroyed, 'Cannot post ${message.runtimeType} to a destroyed $runtimeType.');
    process(message);
  }

  /// Updates this entity, its components, and its children by [Update.dt]
  /// seconds.
  @nonVirtual
  void update(Update update) {
    if (!activity.updates) return;
    process(update);

    final components = _components;

    if (components != null) {
      for (var i = 0; i < components.length; i += 1) {
        final component = components[i];

        if (component.activity.updates) {
          component.process(update);
        }
      }
    }

    final children = _children?.entities;
    if (children == null || children.isEmpty) return;

    for (var i = 0; i < children.length; i += 1) {
      children[i].update(update);
    }
  }

  /// Renders this entity's components and enabled children to [canvas], under
  /// its transform, [opacity], and [clip].
  void render(Canvas canvas) {
    final opacity = this.opacity;
    if (opacity <= 0) return;
    final layered = opacity < 1;

    if (layered) {
      canvas.saveLayer(null, _paint!);
    }

    canvas.save();
    canvas.transform(renderTransform);

    if (clip) {
      shape.clip(canvas);
    }

    final components = _components;

    if (components != null) {
      for (var i = 0; i < components.length; i += 1) {
        final component = components[i];

        if (component.activity.renders) {
          component.render(canvas);
        }
      }
    }

    final children = _children?.entities;

    if (children != null) {
      for (var i = 0; i < children.length; i += 1) {
        final child = children[i];

        if (child.activity.renders) {
          child.render(canvas);
        }
      }
    }

    canvas.restore();

    if (layered) {
      canvas.restore();
    }
  }

  /// Renders the debug overlay for this entity, its components, and its
  /// children to [canvas], marking [position] with a 2-pixel cross before
  /// anything else draws.
  ///
  /// The cross draws under every [DebugMode], in that mode's own color, so a
  /// wireframe of one category still says where each entity sits.
  /// [DebugMode.spatial] adds the bounds.
  void debugRender(Canvas canvas) {
    canvas.save();
    canvas.transform(renderTransform);

    final debug = Ignis.debug;
    final paint = debug.paint;
    final anchor = pointAt(this.anchor);
    final x = anchor.x;
    final y = anchor.y;

    canvas.drawLine(.new(x - 1, y), .new(x + 1, y), paint);
    canvas.drawLine(.new(x, y - 1), .new(x, y + 1), paint);

    if (debug.draws(.spatial)) {
      canvas.drawRect(shape.rect(), paint);
    }

    final components = _components;

    if (components != null) {
      for (var i = 0; i < components.length; i += 1) {
        final component = components[i];

        if (component.activity.renders) {
          component.debugRender(canvas);
        }
      }
    }

    final children = _children?.entities;

    if (children != null) {
      for (var i = 0; i < children.length; i += 1) {
        final child = children[i];

        if (child.activity.renders) {
          child.debugRender(canvas);
        }
      }
    }

    canvas.restore();
  }

  // #region Activity

  /// A bitmap indicating what kinds of activity this entity responds to.
  ///
  /// Defaults to [Activity.all].
  Activity activity;

  /// Whether this entity participates in all activity.
  ///
  /// If even one bit of [activity] is disabled, this is false.
  bool get enabled => activity == .all;

  /// Enables this entity.
  @mustCallSuper
  void enable() => activity = .all;

  /// Disables this entity.
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

  // #region Opacity

  Paint? _paint;

  /// This subtree's opacity, 0 to 1. Defaults to 1.
  ///
  /// At 1 the subtree renders plainly, and at 0 it skips rendering entirely. In
  /// both of these scenarios, there is no performance cost.
  ///
  /// When opacity is *between* 0 and 1, the subtree is wrapped in a special
  /// canvas operation, `saveLayer`, fading it as one image. However, `saveLayer`
  /// is extraordinarily expensive with respect to performance, so this parameter
  /// must only be used for effects that truly require them, like transitions,
  /// fades, and dims.
  ///
  /// For handling the opacity of a single sprite, use `Paint`'s alpha channel
  /// directly, or take advantage of effects like `ColorOpacityEffect`
  /// and `ColorFilterOpacityEffect` to control alpha over time.
  @override
  double get opacity => _paint?.color.a ?? 1;

  @override
  set opacity(double value) {
    if (_paint == null && value >= 1) return;
    final paint = _paint ??= Paint();
    paint.color = paint.color.withValues(alpha: clampDouble(value, 0, 1));
  }

  // #endregion

  // #region Components

  List<Component>? _components;

  /// This entity's components, in the order they were added.
  late final Components components = ._(this);

  // #endregion

  // #region Children

  _Children? _children;

  /// This entity's children, in [priority] order.
  Iterable<Entity> get children {
    return _children?.entities ?? const [];
  }

  /// This entity's children, in reverse [priority] order.
  Iterable<Entity> get reverseChildren sync* {
    final children = _children?.entities;
    if (children == null) return;

    for (var i = children.length - 1; i >= 0; i -= 1) {
      yield children[i];
    }
  }

  /// This entity's children of type [T], in [priority] order.
  ///
  /// The returned object is a live, read-only view of all [T] children.
  Iterable<T> query<T extends Entity>() => (_children ??= _Children()).query<T>();

  /// This entity's descendants in depth-first preorder.
  Iterable<Entity> get descendants sync* {
    for (final child in children) {
      yield child;
      yield* child.descendants;
    }
  }

  /// Checks if this entity contains the [other] entity.
  bool contains(Entity other) => //
      descendants.any((descendant) => identical(descendant, other));

  // #endregion

  // #region Priority

  int _priority;
  _ReorderTask? _reorderTask;

  /// This entity's order in updating and rendering in its parent.
  ///
  /// The default priority is 0. Children that share a priority are kept in
  /// insertion order, like a queue.
  int get priority => _priority;

  /// This entity's [priority], or what it is scheduled to be.
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

  /// True while this entity is the root of a scene.
  bool get isRoot => identical(_scene?.root, this);

  /// True while this entity is part of a scene.
  bool get isMounted => _scene != null;

  bool _destroyed = false;

  /// True once this entity has been unmounted. A destroyed entity is never
  /// mounted again.
  bool get isDestroyed => _destroyed;

  /// This entity's current scene. Only valid while [isMounted].
  Scene get scene {
    assert(isMounted, 'This entity is not mounted yet.');
    return _scene!;
  }

  @internal
  void mount(Scene scene) {
    if (_destroyed) {
      throw StateError('Cannot mount a destroyed entity.');
    }

    if (isMounted) {
      throw StateError('Cannot mount a mounted entity.');
    }

    if (parent != null) {
      throw StateError('Cannot mount an entity that has a parent.');
    }

    _reparentTask?.cancel();
    _reparentTask = null;
    _mount(scene);
  }

  @internal
  void unmount() {
    _unmount();
  }

  void _mount(Scene scene) {
    _scene = scene;

    try {
      process(const Build());
    } finally {
      final components = _components?.toList(growable: false);

      if (components != null) {
        for (final component in components) {
          if (!identical(component._entity, this)) continue;
          component._build();
        }
      }

      final children = _children?.entities;

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

    final components = _components;

    if (components != null) {
      for (var i = components.length - 1; i >= 0; i -= 1) {
        components[i]._destroy();
      }
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

  Entity? _parent;
  _ReparentTask? _reparentTask;

  /// The parent that owns this entity, if any.
  Entity? get parent => _parent;

  /// The [parent] that owns or is scheduled to own this entity, if any.
  Entity? get incomingParent => _reparentTask != null ? _reparentTask!.parent : parent;

  /// True if this entity has a non-null [parent].
  bool get hasParent => parent != null;

  /// Checks if this entity owns the [other] entity.
  bool owns(Entity other) => identical(this, other.parent);

  /// This entity's ancestors in the tree.
  Iterable<Entity> get ancestors sync* {
    var ancestor = parent;

    while (ancestor != null) {
      yield ancestor;
      ancestor = ancestor.parent;
    }
  }

  /// True if [entity] is, or soon will be, an ancestor of this entity.
  bool cycles(Entity entity) {
    Entity? current = this;

    while (current != null) {
      if (identical(current, entity)) return true;
      current = current.incomingParent;
    }

    return false;
  }

  /// Adds [entity] to this entity. The entity is returned.
  ///
  /// Entities cannot be added to themselves or their descendants. A mounted or
  /// destroyed entity cannot be added either. Until it mounts, adding an entity
  /// elsewhere moves it, and adding it to its current parent is a no-op.
  T add<T extends Entity>(T entity) {
    if (identical(this, entity)) {
      throw StateError('Cannot add an entity to itself.');
    }

    if (cycles(entity)) {
      throw StateError('Cannot add an entity to its descendant.');
    }

    if (entity.isRoot) {
      throw StateError('Cannot add a scene root to another entity.');
    }

    if (entity._destroyed) {
      throw StateError('Cannot add a destroyed entity.');
    }

    if (entity.isMounted) {
      throw StateError('Cannot add a mounted entity.');
    }

    if (identical(entity.incomingParent, this)) {
      return entity;
    }

    entity._scheduleParent(this);
    return entity;
  }

  /// Adds all [entities] to this entity.
  void addAll(Iterable<Entity> entities) => entities.forEach(add);

  /// Adds this entity to the target [entity].
  void attach(Entity entity) => entity.add(this);

  /// Removes the child [entity].
  ///
  /// Returns true if the entity was owned by this entity and its removal was
  /// accepted. Removing a parentless entity, an entity not owned by this
  /// entity, or an entity already awaiting removal, is a no-op that returns
  /// `false`.
  ///
  /// If the entity was scheduled to be added, that operation is cancelled
  /// instead.
  bool remove(Entity entity) {
    if (!identical(entity.incomingParent, this)) return false;
    entity._scheduleParent(null);
    return true;
  }

  /// Removes all children.
  void removeAll() {
    for (final child in reverseChildren) {
      remove(child);
    }
  }

  /// Removes this entity from its parent.
  bool detach() => incomingParent?.remove(this) ?? false;

  void _scheduleParent(Entity? parent) {
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

  void _reparent(Entity? nextParent) {
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

  // #region Traversal

  /// This entity and its subtree, in postorder: every child before its parent,
  /// and children in reverse [priority] order.
  ///
  /// [prune] skips an entity and everything beneath it, so a walk can stop at
  /// a subtree rather than filter it out afterwards.
  @nonVirtual
  Iterable<Entity> traverse({bool Function(Entity entity)? prune}) sync* {
    if (prune != null && prune(this)) return;

    for (final child in reverseChildren) {
      yield* child.traverse(prune: prune);
    }

    yield this;
  }

  // #endregion

  // #region Dependency Injection

  Map<Type, dynamic>? _providers;
  Map<Type, dynamic>? _dependencies;

  /// Drops this entity's cached dependencies.
  ///
  /// TODO: Really bad naming between this and `_forgetAncestry`. One is shallow
  ///   while the other is deep. Think of something better.
  void _dropAncestry() {
    _dependencies = null;
  }

  /// Drops cached dependencies for this entity and its entire subtree.
  void _forgetAncestry() {
    _dropAncestry();
    final children = _children?.entities;
    if (children == null) return;

    for (final child in children) {
      child._forgetAncestry();
    }
  }

  /// Provides [value] as this entity's instance of [T], overwriting any value
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

  /// Reads the nearest instance of [T] provided by this entity or an
  /// ancestor, checking this entity first. Returns null if none was provided.
  ///
  /// Cached until unmount, misses included.
  ///
  /// Throws a [StateError] if this entity is not mounted yet.
  T? readOrNull<T>() {
    final dependencies = _dependencies ??= {};
    if (dependencies.containsKey(T)) return dependencies[T] as T?;

    if (!isMounted) {
      throw StateError('Cannot read $T because this entity is not mounted yet.');
    }

    Entity? entity = this;

    while (entity != null) {
      final providers = entity._providers;

      if (providers != null && providers.containsKey(T)) {
        return dependencies[T] = providers[T] as T;
      }

      entity = entity.parent;
    }

    return dependencies[T] = null;
  }

  // #endregion

  // #region Space

  final MMatrix3 _lastAbsoluteTransform = .identity();

  /// This entity's transform composed with every ancestor, stopping at (but
  /// not including) [upTo].
  ///
  /// The returned matrix is owned by this entity and should not be retained.
  MMatrix3 absoluteTransform([Entity? upTo]) {
    final transform = _lastAbsoluteTransform;
    transform.setFrom(localTransform);
    var current = parent;

    while (current != null && !identical(current, upTo)) {
      transform.premultiply(current.localTransform);
      current = current.parent;
    }

    return transform;
  }

  /// This entity's [position], composed with the transform of every ancestor,
  /// stopping at (but not including) [upTo].
  ///
  /// The returned vector is owned by the caller.
  MVector2 scenePosition([Entity? upTo]) {
    final absolute = MVector2.copy(position);
    var current = parent;

    while (current != null && !identical(current, upTo)) {
      absolute.transform(current.localTransform);
      current = current.parent;
    }

    return absolute;
  }

  /// This entity's [position] in scene space.
  ///
  /// The returned vector is owned by the caller.
  MVector2 get absolutePosition => scenePosition();

  // #endregion
}
