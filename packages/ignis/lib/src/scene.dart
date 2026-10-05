// SPDX-AI-Disclosure: none

import 'dart:ui' hide Scene;

import 'package:flutter/foundation.dart';
import 'package:ignis/src/core.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/shape.dart';
import 'package:ignis/src/tree.dart';

/// A controller for a mounted [Node] tree.
///
/// TODO: Document further.
class Scene<T extends Node> {
  /// This scene's root. Cannot be modified.
  final T root;

  static final List<Scene> _live = [];

  /// Every scene currently mounted, the most recent first.
  static Iterable<Scene> get live => _live.reversed;

  @internal
  final tree = QueuedTree();

  bool _mounted = true;
  bool _sized = false;
  bool _reassembling = false;
  bool _paused = false;

  Vector2 _size = .zero;
  Rectangle _shape = const Rectangle(.zero);

  /// Current scene size, updated on every resize via [resize].
  Vector2 get size => _size;

  /// This scene's area, updated on every resize via [resize].
  Shape get shape => _shape;

  /// Whether the scene has been [resize]d at least once.
  bool get hasSize => _sized;

  /// Whether this scene is frozen: it neither updates nor advances time.
  bool get paused => _paused;

  /// Freezes this scene, so it stops updating and advancing time.
  @mustCallSuper
  void pause() {
    if (_paused) return;
    _paused = true;
    onPause.emit(true);
  }

  /// Unfreezes this scene, so it resumes updating.
  @mustCallSuper
  void resume() {
    if (!_paused) return;
    _paused = false;
    onPause.emit(false);
  }

  @nonVirtual
  set paused(bool value) {
    if (value) {
      pause();
    } else {
      resume();
    }
  }

  /// Emitted whenever [paused] changes.
  final onPause = Signal1<bool>();

  @internal
  Scene({
    required this.root,
  }) {
    _live.add(this);
  }

  void update(double dt) {
    assert(_mounted, 'Cannot update a destroyed scene.');
    tree.flush();
    root.update(dt);
  }

  void reassemble() {
    assert(_mounted, 'Cannot reassemble a destroyed scene.');
    if (_reassembling) return;
    _reassembling = true;

    try {
      root.reassemble();
    } finally {
      _reassembling = false;
    }
  }

  /// Renders this scene to [canvas].
  void render(Canvas canvas) {
    assert(_mounted, 'Cannot render a destroyed scene.');
    if (!root.activity.renders) return;
    root.render(canvas);
    if (Debug.instance.enabled) root.debugRender(canvas);
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
    root.resize(size);
  }

  /// Unmounts the tree, permanently. Idempotent; every other way of driving
  /// this scene asserts once it has been destroyed.
  void destroy() {
    if (!_mounted) return;
    _mounted = false;
    _live.remove(this);
    root.unmount();
  }
}
