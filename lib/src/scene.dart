part of 'core.dart';

/// A controller for a mounted [Node] tree.
///
/// TODO: Document further.
class Scene<T extends Node> {
  /// This scene's root. Cannot be modified.
  final T node;

  final _tree = _Tree();
  bool _mounted = true;
  bool _sized = false;
  bool _reassembling = false;

  Vector2 _size = .zero;

  /// Current scene size, updated on every resize via [resize].
  Vector2 get size => _size;

  /// Whether the scene has been [resize]d at least once.
  bool get hasSize => _sized;

  Scene._({
    required this.node,
  }) {
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

    try {
      node.reassemble();
    } finally {
      _reassembling = false;
    }
  }

  /// Renders this scene to [canvas].
  ///
  /// Pass [debug] to additionally render the debug overlay for this frame.
  void render(
    Canvas canvas, {
    bool debug = false,
  }) {
    assert(_mounted, 'Cannot render a destroyed scene.');
    if (!node.enabled) return;
    node.render(canvas);
    if (debug) node.debugRender(canvas);
  }

  void resize(double width, double height) {
    assert(_mounted, 'Cannot resize a destroyed scene.');

    if (_sized && //
        _size.x == width &&
        _size.y == height) {
      return;
    }

    _size = .new(width, height);
    _sized = true;
    node._resize(size);
  }

  /// Unmounts the tree, permanently. Idempotent; every other way of driving
  /// this scene asserts once it has been destroyed.
  void destroy() {
    if (!_mounted) return;
    _mounted = false;
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
