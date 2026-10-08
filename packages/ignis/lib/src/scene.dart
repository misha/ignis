// SPDX-AI-Disclosure: none

import 'dart:ui' hide Scene;

import 'package:ignis/src/core.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/scheduler.dart';
import 'package:ignis/src/shape.dart';

/// A controller for a mounted [Entity] tree.
///
/// TODO: Document further.
class Scene<T extends Entity> with Scheduler {
  /// This scene's root. Cannot be modified.
  final T root;

  bool _mounted = true;
  bool _sized = false;

  final _update = Update(0);

  Vector2 _size = .zero;
  Rectangle _shape = const Rectangle(.zero);

  /// Current scene size, updated on every resize via [resize].
  Vector2 get size => _size;

  /// This scene's area, updated on every resize via [resize].
  Shape get shape => _shape;

  /// Whether the scene has been [resize]d at least once.
  bool get hasSize => _sized;

  /// Whether this scene is frozen: it neither updates nor advances time.
  bool paused = false;

  Scene(this.root) {
    root.mount(this);
  }

  void update(double dt) {
    assert(_mounted, 'Cannot update a destroyed scene.');
    flush();
    _update.dt = dt;
    root.update(_update);
  }

  /// Renders this scene to [canvas].
  void render(Canvas canvas) {
    assert(_mounted, 'Cannot render a destroyed scene.');
    if (!root.activity.renders) return;
    root.render(canvas);
    if (!Debug.instance.enabled) return;
    root.debugRender(canvas);
  }

  void resize(double width, double height) {
    assert(_mounted, 'Cannot resize a destroyed scene.');

    if (_sized && //
        _size.x == width &&
        _size.y == height) {
      return;
    }

    _size = .new(width, height);
    _shape = Rectangle(_size);
    _sized = true;
  }

  /// Posts [Reassemble] to every entity and component in this scene, after a
  /// hot reload.
  void reassemble() {
    assert(_mounted, 'Cannot reassemble a destroyed scene.');

    for (final entity in root.traverse()) {
      entity.post(const Reassemble());

      for (final component in entity.components) {
        component.post(const Reassemble());
      }
    }
  }

  /// Unmounts the tree, permanently. Idempotent; every other way of driving
  /// this scene asserts once it has been destroyed.
  void destroy() {
    if (!_mounted) return;
    _mounted = false;
    root.unmount();
    flush();
  }
}
