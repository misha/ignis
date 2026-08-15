part of 'core.dart';

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
