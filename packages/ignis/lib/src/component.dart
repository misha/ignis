part of 'core.dart';

/// A part of an [Entity].
///
/// A component belongs to exactly one [entity] and has no children and no
/// transform of its own. It processes [Build], [Update], [Destroy], and
/// [Reassemble] from its entity, and posts its own messages to its entity.
///
/// A component lives once, like an entity. Removing it from a mounted entity
/// destroys it.
///
/// **Do not make [process] `async`.**
class Component with Address {
  /// Creates a new component.
  ///
  /// [activity] sets whether the component ticks and renders.
  /// Defaults to [Activity.all].
  Component({
    this.id,
    bool? enabled,
  }) : activity = (enabled ?? true) ? .all : .none;

  /// The name effects on the same entity target this component by, if any.
  final Symbol? id;

  /// Executes all this component's behavior for the given [message].
  @visibleForOverriding
  void process(Message message) {
    // Nothing to do.
  }

  /// Processes [message] on this component.
  @override
  @nonVirtual
  void post(Message message) {
    assert(!_destroyed, 'Cannot post ${message.runtimeType} to a destroyed $runtimeType.');
    process(message);
  }

  /// Paints this component to [canvas], in its entity's local space.
  void render(Canvas canvas) {
    // Nothing to do.
  }

  /// Paints this component's debug overlay to [canvas], in the same space as
  /// [render].
  void debugRender(Canvas canvas) {
    // Nothing to do.
  }

  // #region Activity

  /// A bitmap indicating what kinds of activity this component responds to.
  ///
  /// Defaults to [Activity.all].
  Activity activity;

  /// Whether this component participates in all activity.
  ///
  /// If even one bit of [activity] is disabled, this is false.
  bool get enabled => activity == .all;

  /// Enables this component.
  @mustCallSuper
  void enable() => activity = .all;

  /// Disables this component.
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

  // #region Entity

  Entity? _entity;
  _AttachTask? _attachTask;
  bool _destroyed = false;

  /// The entity this component belongs to. Only valid while [isAttached].
  Entity get entity {
    assert(isAttached, '$runtimeType is not attached to an entity yet.');
    return _entity!;
  }

  /// The [entity] this component belongs to or is scheduled to belong to, if
  /// any.
  Entity? get incomingEntity => _attachTask != null ? _attachTask!.entity : _entity;

  /// True while this component belongs to an entity.
  bool get isAttached => _entity != null;

  /// True while this component's entity is part of a scene.
  bool get isMounted => _entity?.isMounted ?? false;

  /// True once this component has been removed from a mounted entity, or its
  /// entity unmounted. A destroyed component is never mounted again.
  bool get isDestroyed => _destroyed;

  /// Removes this component from its entity.
  bool detach() => incomingEntity?.components.remove(this) ?? false;

  void _scheduleEntity(Entity? entity) {
    _attachTask?.cancel();
    _attachTask = null;
    if (identical(entity, _entity)) return;
    final task = _AttachTask(this, entity);
    final scene = _entity?._scene ?? entity?._scene;

    if (scene != null) {
      scene.schedule(task);
      _attachTask = task;
    } else {
      task.execute();
    }
  }

  void _attach(Entity? next) {
    _attachTask = null;
    final outgoing = _entity?._scene;
    final incoming = next?._scene;

    try {
      if (outgoing != null) _destroy();
    } finally {
      _entity?._components?.remove(this);
      if (next != null) (next._components ??= []).add(this);
      _entity = next;
      if (incoming != null) _build();
    }
  }

  void _build() {
    process(const Build());
  }

  void _destroy() {
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
    } finally {
      _destroyed = true;
    }
  }

  // #endregion
}

/// An entity's components, in the order they were added.
final class Components extends Iterable<Component> {
  final Entity _entity;

  Components._(this._entity);

  @override
  Iterator<Component> get iterator => (_entity._components ?? const <Component>[]).iterator;

  /// Adds [component] to this entity. The component is returned.
  ///
  /// A mounted or destroyed component cannot be added. Until it mounts,
  /// adding a component elsewhere moves it, and adding it to its current
  /// entity is a no-op.
  T add<T extends Component>(T component) {
    if (component.isDestroyed) {
      throw StateError('Cannot add a destroyed component.');
    }

    if (component.isMounted) {
      throw StateError('Cannot add a mounted component.');
    }

    if (identical(component.incomingEntity, _entity)) {
      return component;
    }

    component._scheduleEntity(_entity);
    return component;
  }

  /// Adds all [components] to this entity.
  void addAll(Iterable<Component> components) => components.forEach(add);

  /// Removes [component] from this entity.
  ///
  /// Returns true if the component belonged to this entity and its removal
  /// was accepted. If it was scheduled to be added, that operation is
  /// cancelled instead.
  bool remove(Component component) {
    if (!identical(component.incomingEntity, _entity)) return false;
    component._scheduleEntity(null);
    return true;
  }
}
