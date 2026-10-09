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
  /// [enabled] sets whether the component ticks and renders.
  /// Defaults to true.
  ///
  /// [priority] controls this component's order when updating and rendering.
  /// Defaults to 0.
  Component({
    this.id,
    bool? enabled,
    int? priority,
  }) : activity = (enabled ?? true) ? .all : .none,
       _priority = priority ?? 0;

  /// Used to reference this component under its entity.
  final Symbol? id;

  /// Executes all this component's behavior for the given [message].
  @visibleForOverriding
  void process(Message message) {
    // Nothing to do.
  }

  /// Paints this component to [canvas], in its entity's local space.
  @visibleForOverriding
  void render(Canvas canvas) {
    // Nothing to do.
  }

  /// Paints this component's debug overlay to [canvas], in the same space as
  /// [render].
  @visibleForOverriding
  void debugRender(Canvas canvas) {
    // Nothing to do.
  }

  /// Processes [message] on this component.
  @override
  @nonVirtual
  void post(Message message) {
    assert(
      isBuilt,
      'Cannot post ${message.runtimeType} to a $runtimeType that is not built.',
    );

    process(message);
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
  set enabled(bool value) => value ? enable() : disable();

  // #endregion

  // #region Priority

  int _priority;

  /// This component's order in updating and rendering in its entity.
  ///
  /// The default priority is 0. Components that share a priority are kept in
  /// insertion order, like a queue.
  int get priority => _priority;

  @nonVirtual
  set priority(int value) {
    Task(() {
      if (value == _priority) return;
      _priority = value;
      _entity?._components?.reorder(this);
    }).run(_entity?._scene?.scheduler);
  }

  // #endregion

  // #region Lifecycle

  Lifecycle _lifecycle = .initial;

  /// Where this component is in its one life.
  Lifecycle get lifecycle => _lifecycle;

  /// Whether this component has a scene.
  bool get isMounted => _lifecycle.has(.mounted);

  /// Whether this component has been built.
  bool get isBuilt => _lifecycle.has(.built);

  /// Whether this component has been destroyed.
  bool get isDestroyed => _lifecycle.has(.destroyed);

  // #endregion

  // #region Entity

  Entity? _entity;

  /// The entity this component belongs to. Only valid while [isAttached].
  Entity get entity {
    assert(isAttached, '$runtimeType is not attached to an entity yet.');
    return _entity!;
  }

  /// True while this component belongs to an entity.
  bool get isAttached => _entity != null;

  /// Adds this component to [entity].
  void attach(Entity entity) => entity.addComponent(this);

  /// Removes this component from its entity.
  void detach() => _entity?.removeComponent(this);

  void _build() {
    _lifecycle = .building;

    try {
      process(const Build());
    } catch (_) {
      _destroy();
      rethrow;
    }

    _lifecycle = .running;
  }

  void _destroy() {
    if (!isMounted) return;

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
    } finally {
      _lifecycle = .destroyed;
    }
  }

  // #endregion
}
