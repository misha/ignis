part of 'core.dart';

/// A [Message] that Ignis itself runs.
sealed class SystemMessage extends Message {
  const SystemMessage();
}

/// The node was mounted to a scene.
final class Build extends SystemMessage {
  const Build();
}

/// The scene advanced by [dt] seconds.
final class Update extends SystemMessage {
  double dt;

  Update(this.dt);
}

/// The node paints to [canvas], in its own coordinate space.
final class Draw extends SystemMessage {
  Canvas canvas;

  Draw(this.canvas);
}

/// The node paints its debug overlay to [canvas], in the same space as [Draw].
final class DebugDraw extends SystemMessage {
  Canvas canvas;

  DebugDraw(this.canvas);
}

/// The node was unmounted from its scene.
final class Destroy extends SystemMessage {
  const Destroy();
}

/// The app's code was hot reloaded. Only ever processed in debug builds.
final class Reassemble extends SystemMessage {
  const Reassemble();
}
