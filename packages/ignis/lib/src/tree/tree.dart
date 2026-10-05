import 'package:flutter/foundation.dart';
import 'package:ignis/src/scheduler.dart';

part 'tree_children.dart';
part 'tree_state.dart';

/// A scheduler-based tree with mount/unmount semantics.
///
/// Structural changes ([add], [remove], and priority changes) are handed to a
/// [scheduler], which decides when they run.
///
/// Items in the tree are called "nodes", which incidentally matches Ignis'
/// `Node` documentation. A completely random, but useful, coincidence.
abstract class Tree<T extends Tree<T>> {
  TreeState<T> _state = Detached<T>._();
  TreeChildren<T>? _children;

  TreeState<T> get state => _state;
  int get priority;

  @protected
  Scheduler get scheduler;

  @protected
  void mounted();

  @protected
  void unmounted();

  @protected
  void reparented();

  T get _self => this as T;

  /// True while this node is part of a scene.
  bool get isMounted => _state.isMounted;

  /// True while this node awaits removal at the next flush.
  bool get isRemoving => _state is Removing<T>;

  /// This node's direct children.
  Iterable<T> get children => _children?.nodes ?? const [];

  /// This node's direct children of type [S], in [priority] order.
  ///
  /// The returned object is a live, read-only view of all [S] children.
  Iterable<S> query<S extends T>() => (_children ??= TreeChildren<T>()).query<S>();

  /// The parent that owns this node, or null when it is parentless.
  T? get parent => _state.parent;

  /// True if this node has a non-null parent.
  bool get hasParent => parent != null;

  /// This node's ancestors in the tree.
  Iterable<T> get ancestors sync* {
    var ancestor = parent;

    while (ancestor != null) {
      yield ancestor;
      ancestor = ancestor.parent;
    }
  }

  /// This node's descendants in depth-first preorder.
  Iterable<T> get descendants sync* {
    for (final child in children) {
      yield child;
      yield* child.descendants;
    }
  }

  /// Checks if this node contains the [other] node in its tree.
  bool contains(T other) => //
      descendants.any((descendant) => identical(descendant, other));

  /// Checks if this node owns the [other] node.
  bool owns(T other) => identical(this, other.parent);

  /// True if [node] is (or soon will be) an ancestor of this node.
  bool cycles(T node) {
    T? current = _self;

    while (current != null) {
      if (identical(current, node)) return true;
      final state = current._state;

      switch (state) {
        case Arriving(:final target) || Moving(:final target):
          current = target;

        default:
          current = state.parent;
      }
    }

    return false;
  }

  /// This node and its subtree, in postorder: every child before its parent,
  /// and children in reverse [priority] order.
  ///
  /// [prune] skips a node and everything beneath it, so a walk can stop at a
  /// subtree rather than filter it out afterwards.
  @nonVirtual
  Iterable<T> traverse({bool Function(T node)? prune}) sync* {
    if (prune != null && prune(_self)) return;
    final children = _children?.nodes;

    if (children != null) {
      for (var i = children.length - 1; i >= 0; i -= 1) {
        yield* children[i].traverse(prune: prune);
      }
    }

    yield _self;
  }

  S add<S extends T>(S node) {
    if (identical(this, node)) {
      throw StateError('Cannot add a node to itself.');
    }

    if (cycles(node)) {
      throw StateError('Cannot add a node to its descendant.');
    }

    switch (node._state) {
      case Detached():
        _admit(node);

      case Attached(parent: final from):
        if (identical(from, this)) return node;
        from._release(node);
        _admit(node);

      case Arriving(:final target):
        if (identical(target, this)) return node;
        node._state = Detached._();
        _admit(node);

      case Root():
        throw StateError('Cannot add a root to another node.');

      case Mounted(parent: final from):
        if (identical(from, this)) return node;
        _move(node, from);

      case Moving(:final from, :final target):
        if (identical(target, this)) return node;

        if (identical(from, this)) {
          node._state = Mounted._(_self);
          return node;
        }

        _move(node, from);

      case Removing(parent: final from):
        if (identical(from, this)) {
          node._state = Mounted._(_self);
          return node;
        }

        _move(node, from);
    }

    return node;
  }

  /// Adds all [nodes] to this node.
  void addAll(Iterable<T> nodes) => nodes.forEach(add);

  /// Adds this node to the target [node].
  void attach(T node) => node.add(_self);

  /// Removes the child [node].
  ///
  /// Returns true if the node was owned by this node and its removal was
  /// accepted. Removing a parentless node, a node not owned by this node, or a
  /// node already awaiting removal, is a no-op that returns `false`.
  ///
  /// A node still awaiting its own addition is cancelled outright, so an add
  /// and a remove queued in the same frame settle to nothing.
  bool remove(T node) {
    switch (node._state) {
      case Attached(parent: final from):
        if (!identical(from, this)) return false;
        _release(node);
        return true;

      case Mounted(parent: final from):
        if (!identical(from, this)) return false;
        _depart(node);
        return true;

      case Arriving(:final target):
        if (!identical(target, this)) return false;
        node._state = Detached._();
        return true;

      case Moving(:final from, :final target):
        if (!identical(target, this)) return false;
        from._depart(node);
        return true;

      case Detached() || Root() || Removing():
        return false;
    }
  }

  /// Removes all children.
  void removeAll() {
    final children = _children?.nodes;
    if (children == null) return;

    for (var i = children.length - 1; i >= 0; i -= 1) {
      remove(children[i]);
    }
  }

  /// Removes this node from its parent, or from the parent it is on its way to.
  bool detach() {
    switch (_state) {
      case Arriving(:final target) || Moving(:final target):
        return target.remove(_self);

      case final state:
        final parent = state.parent;
        if (parent == null) return false;
        return parent.remove(_self);
    }
  }

  @protected
  void reposition() {
    final parent = this.parent;
    if (parent == null) return;

    scheduler.schedule(() {
      parent._children?.reorder(_self);
    });
  }

  @protected
  void mount() {
    switch (_state) {
      case Detached():
        _mount();

      case final state:
        throw StateError('Cannot mount a node while $state.');
    }
  }

  @protected
  void unmount() {
    _unmount();
  }

  void _own(T node) {
    switch (node._state) {
      case Moving(:final from):
        // A node moved here from another scene leaves that one first. One moved
        // within this scene is already standing, and must not be rebuilt.
        if (identical(scheduler, node.scheduler)) {
          from._release(node);
          (_children ??= TreeChildren<T>()).add(node);
          node._state = Mounted._(_self);
          return;
        }

        node._unmount();

      case Detached() || Arriving():
        break;

      case final state:
        throw StateError('Cannot own a node while $state.');
    }

    (_children ??= TreeChildren<T>()).add(node);
    node._state = Attached._(_self);
    if (isMounted) node._mount();
  }

  void _admit(T node) {
    node._state = Arriving._(_self);

    scheduler.schedule(() {
      _arrive(node);
    });
  }

  void _move(T node, T from) {
    node._state = Moving._(from, _self);

    node.scheduler.schedule(() {
      _arrive(node);
    });
  }

  void _arrive(T node) {
    switch (node._state) {
      case Arriving(:final target) || Moving(:final target):
        if (identical(target, this)) _own(node);

      default:
        break;
    }
  }

  void _depart(T node) {
    node._state = Removing._(_self);

    node.scheduler.schedule(() {
      final state = node._state;
      if (state is! Removing<T>) return;
      if (!identical(state.parent, this)) return;
      node._unmount();
    });
  }

  void _release(T node) {
    _children?.remove(node);
    node._state = Detached._();
    node._reparent();
  }

  void _reparent() {
    reparented();

    for (final child in children) {
      child._reparent();
    }
  }

  void _mount() {
    switch (_state) {
      case Detached():
        _state = Root._();

      case Attached(:final parent):
        _state = Mounted._(parent);

      case final state:
        throw StateError('Cannot mount a node while $state.');
    }

    mounted();

    for (final child in children.toList(growable: false)) {
      final state = child._state;
      if (state is! Attached<T>) continue;
      if (!identical(state.parent, this)) continue;
      child._mount();
    }
  }

  void _unmount() {
    final children = _children?.nodes;

    if (children != null) {
      for (var i = children.length - 1; i >= 0; i -= 1) {
        children[i]._unmount();
      }
    }

    try {
      unmounted();
    } finally {
      switch (_state) {
        case Root():
          _state = Detached._();

        case Mounted(:final parent):
          _state = Attached._(parent);

        case Removing(:final parent):
          parent._release(_self);

        case Moving(:final from, :final target):
          from._release(_self);
          _state = Arriving._(target);

        case final state:
          throw StateError('Cannot unmount a node while $state.');
      }
    }
  }
}
