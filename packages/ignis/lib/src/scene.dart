// SPDX-AI-Disclosure: none

part of 'core.dart';

/// A controller for a mounted [Node] tree.
///
/// TODO: Document further.
class Scene<T extends Node> {
  /// This scene's root. Cannot be modified.
  final T node;

  static final List<Scene> _live = [];

  /// Every scene currently mounted, the most recent first.
  static Iterable<Scene> get live => _live.reversed;

  final _tree = _Tree();
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

  Scene._({
    required this.node,
  }) {
    _live.add(this);
    node._mount(this);
  }

  void update(double dt) {
    assert(_mounted, 'Cannot update a destroyed scene.');
    _tree.flush();
    node.update(dt);
  }

  void reassemble() {
    assert(_mounted, 'Cannot reassemble a destroyed scene.');
    if (_reassembling) return;
    _reassembling = true;
    Node._generation += 1;

    try {
      node._reassemble();
    } finally {
      _reassembling = false;
    }
  }

  /// Renders this scene to [canvas].
  void render(Canvas canvas) {
    assert(_mounted, 'Cannot render a destroyed scene.');
    if (!node.activity.renders) return;
    node.render(canvas);
    if (Debug.instance.enabled) node.debugRender(canvas);
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
    node._resize(size);
  }

  /// Unmounts the tree, permanently. Idempotent; every other way of driving
  /// this scene asserts once it has been destroyed.
  void destroy() {
    if (!_mounted) return;
    _mounted = false;
    _live.remove(this);
    node._unmount();
  }
}

/// Mounts a node as the root of a new [Scene].
extension Mount<T extends Node> on T {
  /// Mounts this node as the root of a new [Scene] and returns it.
  ///
  /// A no-op that returns the existing [Scene] if already mounted.
  Scene<T> mount() {
    if (isMounted) {
      // TODO: Should this throw a StateError?
      return scene as Scene<T>;
    }

    return Scene._(node: this);
  }
}
