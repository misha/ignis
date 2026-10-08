part of 'core.dart';

/// A [Message] that Ignis itself runs.
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

/// The app's code was hot reloaded. Only ever processed in debug builds.
final class Reassemble extends SystemMessage {
  const Reassemble();
}
