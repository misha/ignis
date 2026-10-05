// SPDX-AI-Disclosure: none

part of 'tree.dart';

/// A node's children: a flat list kept in [Tree.priority] order, alongside
/// an index per queried type.
///
/// Each index built by [query] is maintained as nodes come and go, rather than
/// invalidated and rebuilt, so a query can never go stale and never has to be
/// recomputed. That is only affordable because every mutation runs through
/// this one type.
@internal
final class TreeChildren<T extends Tree<T>> {
  List<T>? _nodes;
  Map<Type, _Index<Object>>? _indexes;

  /// These nodes, in [Tree.priority] order.
  List<T> get nodes => _nodes ?? const [];

  /// The nodes of type [T], in [Tree.priority] order.
  ///
  /// Kept up to date as nodes come and go, so repeated calls cost nothing and
  /// allocate nothing. The first call for a given [T] pays one pass to build
  /// its index.
  Iterable<S> query<S extends T>() {
    final indexes = _indexes ??= {};
    final existing = indexes[S];

    if (existing != null) {
      return (existing as _Index<S>).nodes;
    }

    final index = _Index<S>();

    for (final node in nodes) {
      if (node is S) index.nodes.add(node);
    }

    indexes[S] = index;
    return index.nodes;
  }

  /// Adds [node] at its [Tree.priority] position, and to every index that
  /// accepts it.
  void add(T node) {
    _insert(_nodes ??= [], node);

    final indexes = _indexes;
    if (indexes == null) return;

    for (final index in indexes.values) {
      if (index.accepts(node)) {
        _insert(index.nodes as List<T>, node);
      }
    }
  }

  /// Removes [node] from this egg and every index holding it, reporting
  /// whether it was here at all.
  bool remove(T node) {
    if (_nodes?.remove(node) != true) return false;

    final indexes = _indexes;
    if (indexes == null) return true;

    for (final index in indexes.values) {
      if (index.accepts(node)) {
        index.nodes.remove(node);
      }
    }

    return true;
  }

  /// Moves [node] to its current [Tree.priority] position, here and in every
  /// index holding it.
  void reorder(T node) {
    if (remove(node)) add(node);
  }

  /// Inserts [node] into [nodes], keeping it ordered by [Tree.priority]. Ties
  /// go after the nodes already there.
  void _insert(List<T> nodes, T node) {
    var low = 0;
    var high = nodes.length;

    while (low < high) {
      final middle = (low + high) >> 1;

      if (nodes[middle].priority <= node.priority) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }

    nodes.insert(low, node);
  }
}

/// One type's view of an [TreeChildren], holding every node of type [T].
final class _Index<T extends Object> {
  final List<T> nodes = [];

  /// Whether [node] belongs in [nodes].
  bool accepts(Object node) => node is T;
}
