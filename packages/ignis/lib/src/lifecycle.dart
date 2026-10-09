part of 'core.dart';

const _MOUNTED = 1 << 0;
const _BUILT = 1 << 1;
const _DESTROYED = 1 << 2;

/// A fact that holds during some [Lifecycle] phases.
extension type const LifecycleProperty._(int bits) {
  /// Has a scene.
  static const mounted = LifecycleProperty._(_MOUNTED);

  /// Done with [Build].
  static const built = LifecycleProperty._(_BUILT);

  /// Torn down for good.
  static const destroyed = LifecycleProperty._(_DESTROYED);
}

/// Where an entity or component is in its one life.
extension type const Lifecycle._(int bits) {
  /// Not yet in a scene.
  static const initial = Lifecycle._(0);

  /// In a scene, processing [Build].
  static const building = Lifecycle._(_MOUNTED);

  /// In a scene, ready for any message.
  static const running = Lifecycle._(_MOUNTED | _BUILT);

  /// Out of the scene for good.
  static const destroyed = Lifecycle._(_DESTROYED);

  /// Whether this phase has [property].
  bool has(LifecycleProperty property) => (bits & property.bits) != 0;
}

/// A [Message] sent by Ignis to all entities and components.
sealed class SystemMessage extends Message {
  const SystemMessage();
}

/// The entity was mounted to a scene.
final class Build extends SystemMessage {
  const Build();
}

/// The scene advanced by [dt] seconds.
final class Update extends SystemMessage {
  double dt;

  Update(this.dt);
}

/// The entity was unmounted from its scene.
final class Destroy extends SystemMessage {
  const Destroy();
}

/// The app's code was hot reloaded.
///
/// Only sent in debug builds.
final class Reassemble extends SystemMessage {
  const Reassemble();
}
