part of 'core.dart';

/// What a [Node.process] call is processing.
abstract base class State {
  const State();
}

/// The node was mounted to a scene.
final class Build extends State {
  const Build();
}

/// The scene advanced by [dt] seconds.
final class Update extends State {
  double dt;

  Update(this.dt);
}

/// The node paints to [canvas], in its own coordinate space.
final class Draw extends State {
  Canvas canvas;

  Draw(this.canvas);
}

/// The node paints its debug overlay to [canvas], in the same space as [Draw].
final class DebugDraw extends State {
  Canvas canvas;

  DebugDraw(this.canvas);
}

/// The node was unmounted from its scene.
final class Destroy extends State {
  const Destroy();
}
