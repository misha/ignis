import 'dart:collection';
import 'dart:ui' hide Scene;

import 'package:flutter/foundation.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/signal.dart';

/// The humble node.
///
/// **Overview**
///
/// Nodes are organized in an acyclic, directed tree with children ordered by
/// [priority]. A node is usually initialized once in its constructor, after
/// which it may be added and removed to other nodes repeatedly.
///
/// **Signals**
///
/// Nodes communicate time-sensitive events through signals: named, type-safe
/// message emitters. Use one to report an event to consumers, or as an input
/// to react to external events.
///
/// Conventionally, signals are prefixed with the word `on`. For example, a
/// collision signal should be named `onCollision`. This allows consumers to
/// have a natural-reading constructor, e.g. `onCollision(/* do stuff */);`.
///
/// **Scenes**
///
/// Nodes may be mounted to a [Scene], which drives them with a game loop. When
/// mounted, the scene will propagate through the entire subtree emitting the
/// [onMount] signal on each node, from top to bottom. Unmounting does the
/// reverse, emitting the [onUnmount] signal from the leaves upward.
///
/// **Tree**
///
/// Before being mounted, the [add], [remove], and [priority] tree operations
/// take effect immediately, allowing constructors to freely assemble a subtree
/// long before it goes live.
///
/// Once mounted, however, the same calls are instead merely enqueued. The
/// scene applies pending changes right before the next [update]. As a result,
/// operations for live node trees are always delayed a frame. Although
/// unintuitive, this queue allows the engine to mitigate modification
/// during iteration, and improves performance by batching the changes.
class Node {
  /// Creates a new node.
  ///
  /// [enabled] controls whether the node updates and renders.
  /// Defaults to true.
  ///
  /// [priority] controls this node's order when updating and rendering.
  /// Defaults to 0.
  ///
  /// If [children] are provided, they are immediately added to the node.
  Node({
    bool? enabled,
    int? priority,
    Iterable<Node> children = const [],
  }) : _priority = priority ?? 0,
       _enabled = enabled ?? true {
    addAll(children);
  }

  /// Updates this node by [dt] seconds.
  @visibleForOverriding
  void tick(double dt) {
    // Nothing to do.
  }

  /// Updates this node and its children by [dt] seconds.
  @nonVirtual
  void update(double dt) {
    if (!_enabled) return;
    tick(dt);

    final children = _children;
    if (children == null || children.isEmpty) return;

    for (final child in children) {
      child.update(dt);
    }
  }

  /// Renders this node and its children to [canvas].
  @mustCallSuper
  void render(Canvas canvas) {
    final children = _children;
    if (children == null || children.isEmpty) return;

    for (final child in children) {
      // Rendering is recursive, so this is the only way to stop it.
      // A disabled child must never have `render` called on it.
      if (child._enabled) {
        child.render(canvas);
      }
    }
  }

  /// Renders the debug overlay for this node and its children to [canvas].
  ///
  /// The scene guarantees that [render] will always be called before this
  /// method is called, so implementations are welcome to reuse cached values
  /// to make debug rendering as cheap as possible.
  void debugRender(Canvas canvas) {
    final children = _children;
    if (children == null || children.isEmpty) return;

    for (final child in children) {
      if (child._enabled) {
        child.debugRender(canvas);
      }
    }
  }

  // #region Enabled

  bool _enabled;

  /// Whether this node updates and renders. Defaults to true.
  bool get enabled => _enabled;

  /// Enables this node, so it resumes updating and rendering.
  @mustCallSuper
  void enable() => _enabled = true;

  /// Disables this node, so it stops updating and rendering.
  @mustCallSuper
  void disable() => _enabled = false;

  @nonVirtual
  set enabled(bool value) {
    if (value) {
      enable();
    } else {
      disable();
    }
  }

  // #endregion

  // #region Priority

  int _priority;

  /// This node's order in updating and rendering in its parent. Defaults to 0.
  int get priority => _priority;

  set priority(int value) {
    _priority = value;
    final target = parent;
    if (target == null) return;

    if (target.isMounted) {
      target.scene._tree._reposition(this, target);
    } else {
      target._reposition(this);
    }
  }

  // #endregion

  // #region Signals

  /// Emitted when this node is added to a [Scene].
  final onMount = Signal0();

  /// Emitted when this node is removed from a [Scene].
  final onUnmount = Signal0();

  // #endregion

  // #region Tree

  Scene? _scene;
  List<Node>? _children;
  Node? _parent;
  Node? _pendingParent;
  bool _pendingRemoval = false;

  /// This node's owning scene. Only valid while [isMounted].
  Scene get scene {
    assert(_scene != null, 'This node is not mounted yet.');
    return _scene!;
  }

  /// True while this node is part of a mounted tree.
  bool get isMounted => _scene != null;

  /// This node's direct children.
  Iterable<Node> get children => _children ?? const [];

  /// The parent that owns this node, or null when it is parentless.
  Node? get parent => _parent;

  /// True if this node has a non-null parent.
  bool get hasParent => parent != null;

  /// This node's ancestors in the tree.
  Iterable<Node> get ancestors sync* {
    var ancestor = parent;

    while (ancestor != null) {
      yield ancestor;
      ancestor = ancestor.parent;
    }
  }

  /// This node's descendants in depth-first preorder.
  Iterable<Node> get descendants sync* {
    for (final child in children) {
      yield child;
      yield* child.descendants;
    }
  }

  /// Checks if this node contains the [other] node in its tree.
  bool contains(Node other) => //
      descendants.any((descendant) => identical(descendant, other));

  /// Checks if this node owns the [other] node.
  bool owns(Node other) => identical(this, other.parent);

  /// True if [node] is (or soon will be) an ancestor of this node.
  bool cycles(Node node) {
    Node? current = this;

    while (current != null) {
      if (identical(current, node)) return true;
      current = current._parent ?? current._pendingParent;
    }

    return false;
  }

  void _own(Node node) {
    _insert(node);
    node._parent = this;
    node._pendingParent = null;
    final scene = _scene;
    if (scene != null) node._mount(scene);
  }

  void _disown(Node node) {
    try {
      if (node.isMounted) node._unmount();
    } finally {
      _children?.remove(node);
      node._parent = null;
      node._pendingRemoval = false;
    }
  }

  void _reposition(Node node) {
    final children = _children;
    if (children == null) return;
    final removed = children.remove(node);
    if (!removed) return;
    _insert(node);
  }

  void _insert(Node node) {
    final children = _children ??= [];
    var low = 0;
    var high = children.length;

    while (low < high) {
      final middle = (low + high) >> 1;

      if (children[middle].priority <= node.priority) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }

    children.insert(low, node);
  }

  // #endregion

  // #region Mounting

  void _mount(Scene scene) {
    // TODO: Assert null _scene?
    _scene = scene;
    onMount.emit();
    final children = _children;

    if (children != null && children.isNotEmpty) {
      for (final child in children) {
        child._mount(scene);
      }
    }
  }

  void _unmount() {
    // TODO: Assert non-null _scene?
    final children = _children;

    if (children != null && children.isNotEmpty) {
      for (final child in children) {
        child._unmount();
      }
    }

    onUnmount.emit();
    _scene = null;
  }

  // #endregion

  // #region Attachment

  /// Adds [node] to this node. The node is returned.
  ///
  /// Nodes cannot be added to themselves or their descendants. Adding a child
  /// to its current parent is a no-op.
  T add<T extends Node>(T node) {
    if (owns(node)) {
      return node;
    }

    if (identical(this, node)) {
      throw StateError('Cannot add a node to itself.');
    }

    if (node.hasParent || node._pendingParent != null) {
      // TODO: Why not? Isn't this just a reparenting operation?
      throw StateError('Cannot add a node that already has a parent.');
    }

    if (cycles(node)) {
      throw StateError('Cannot add a node to its descendant.');
    }

    if (isMounted) {
      node._pendingParent = this;
      scene._tree._add(node, this);
    } else {
      _own(node);
    }

    return node;
  }

  /// Adds all [nodes] to this node.
  void addAll(Iterable<Node> nodes) => nodes.forEach(add);

  /// Adds this node to the target [node].
  void attach(Node node) => node.add(this);

  // #endregion

  // #region Detachment

  /// Removes the child [node].
  ///
  /// Returns true if the node was owned by this node and its removal was
  /// accepted. Removing a parentless node, a node not owned by this node, or a
  /// node already awaiting removal, is a no-op that returns `false`.
  bool remove(Node node) {
    if (node._pendingRemoval) return false; // Already being removed.
    if (!owns(node)) return false; // Not our node, not our problem.

    if (isMounted) {
      node._pendingRemoval = true;
      scene._tree._remove(node, this);
    } else {
      _disown(node);
    }

    return true;
  }

  /// Removes all children.
  void removeAll() {
    var children = _children;
    if (children == null || children.isEmpty) return;

    // While mounted, removal is deferred to the next flush, so it's safe to
    // iterate the live list. Otherwise, removal is immediate and would
    // mutate the list out from under this loop, so a snapshot is required.
    if (!isMounted) children = children.toList(growable: false);
    for (final child in children) remove(child);
  }

  /// Removes this node from its parent.
  bool detach() => parent?.remove(this) ?? false;

  // #endregion

  // #region Hit Testing

  /// Finds the topmost enabled node in this subtree whose hit area contains
  /// [point], per [containsPoint].
  ///
  /// Children are searched in reverse [priority] order before this node's
  /// own hit area, mirroring reverse paint order.
  @nonVirtual
  Node? hitTest(Vector2 point) {
    if (!enabled) return null;
    final children = _children;

    if (children != null && children.isNotEmpty) {
      for (final child in children.reversed) {
        final hit = child.hitTest(point);
        if (hit != null) return hit;
      }
    }

    if (containsPoint(point)) return this;
    return null;
  }

  /// Whether this node's hit area contains [point].
  ///
  /// The default implementation always returns false, so plain nodes are
  /// invisible to [hitTest]. Override to opt a node into hit-testing.
  @visibleForOverriding
  bool containsPoint(Vector2 point) => false;

  // #endregion
}

enum _OperationKind {
  add,
  remove,
  reposition,
}

final class _Operation {
  static final _SENTINEL = Node();

  _OperationKind kind = .add;
  Node target = _SENTINEL;
  Node parent = _SENTINEL;

  void recycle() {
    target = _SENTINEL;
    parent = _SENTINEL;
  }
}

final class _Tree {
  final _queue = Queue<_Operation>();
  final _pool = <_Operation>[];

  _Operation _obtain() {
    if (_pool.isNotEmpty) return _pool.removeLast();
    return _Operation();
  }

  void _add(Node target, Node parent) => _queue.addLast(
    _obtain()
      ..kind = .add
      ..target = target
      ..parent = parent,
  );

  void _remove(Node target, Node parent) => _queue.addLast(
    _obtain()
      ..kind = .remove
      ..target = target
      ..parent = parent,
  );

  void _reposition(Node target, Node parent) => _queue.addLast(
    _obtain()
      ..kind = .reposition
      ..target = target
      ..parent = parent,
  );

  /// Applies every pending structural change, in enqueued order.
  void flush() {
    while (_queue.isNotEmpty) {
      final operation = _queue.removeFirst();

      try {
        switch (operation.kind) {
          case .add:
            operation.parent._own(operation.target);

          case .remove:
            operation.parent._disown(operation.target);

          case .reposition:
            operation.parent._reposition(operation.target);
        }
      } finally {
        operation.recycle();
        _pool.add(operation);
      }
    }
  }
}

/// A controller for a mounted [Node] tree.
///
/// TODO: Document further.
class Scene<T extends Node> {
  /// This scene's root. Cannot be modified.
  final T node;

  final _tree = _Tree();
  bool _mounted = true;
  bool _sized = false;

  /// Current scene size, updated on every resize via [resize].
  final Vector2 size = .zero();

  /// Whether the scene has been [resize]d at least once.
  bool get hasSize => _sized;

  /// Emitted whenever the size changes.
  final onResize = Signal1<Vector2>();

  Scene._({
    required this.node,
  }) {
    node._mount(this);
  }

  void update(double dt) {
    _tree.flush();
    node.update(dt);
  }

  /// Renders this scene to [canvas].
  ///
  /// Pass [debug] to additionally render the debug overlay for this frame.
  void render(
    Canvas canvas, {
    bool debug = false,
  }) {
    if (!node.enabled) return;
    node.render(canvas);
    if (debug) node.debugRender(canvas);
  }

  void resize(double width, double height) {
    size.mutate().setValues(width, height);
    _sized = true;
    onResize.emit(size);
  }

  void destroy() {
    // TODO: Actually destroy?
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
