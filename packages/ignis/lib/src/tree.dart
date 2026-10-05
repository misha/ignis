// SPDX-AI-Disclosure: none

part of 'core.dart';

sealed class _Tree {
  const _Tree();

  void add(Node node, Node parent);

  void remove(Node node, Node parent);

  void removeAll(Node parent);

  void reposition(Node node, Node parent);
}

final class _ImmediateTree extends _Tree {
  const _ImmediateTree();

  @override
  void add(Node node, Node parent) {
    parent._own(node);
  }

  @override
  void remove(Node node, Node parent) {
    parent._disown(node);
  }

  @override
  void removeAll(Node parent) {
    for (final child in parent.children.toList(growable: false)) {
      parent._disown(child);
    }
  }

  @override
  void reposition(Node node, Node parent) {
    parent._reposition(node);
  }
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

final class _QueuedTree extends _Tree {
  final _queue = Queue<_Operation>();
  final _pool = <_Operation>[];

  _Operation _obtain() {
    if (_pool.isNotEmpty) return _pool.removeLast();
    return _Operation();
  }

  @override
  void add(Node node, Node parent) {
    node._pendingParent = parent;

    _queue.addLast(
      _obtain()
        ..kind = .add
        ..target = node
        ..parent = parent,
    );
  }

  @override
  void remove(Node node, Node parent) {
    node._pendingRemoval = true;

    _queue.addLast(
      _obtain()
        ..kind = .remove
        ..target = node
        ..parent = parent,
    );
  }

  @override
  void removeAll(Node parent) {
    for (final child in parent.children) {
      parent.remove(child);
    }
  }

  @override
  void reposition(Node node, Node parent) {
    _queue.addLast(
      _obtain()
        ..kind = .reposition
        ..target = node
        ..parent = parent,
    );
  }

  /// Applies every pending structural change, in enqueued order.
  void flush() {
    while (_queue.isNotEmpty) {
      final operation = _queue.removeFirst();

      try {
        switch (operation.kind) {
          case .add:
            // A remove cancelled this addition, so the child never arrived.
            if (!identical(operation.target._pendingParent, operation.parent)) break;
            operation.parent._own(operation.target);

          case .remove:
            // An add cancelled this removal, so the child never left.
            if (!operation.target._pendingRemoval) break;
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
