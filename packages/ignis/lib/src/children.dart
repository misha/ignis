// SPDX-AI-Disclosure: none

part of 'core.dart';

/// A node's children: a flat list kept in [Node.priority] order, alongside
/// an index per queried type.
///
/// Each index built by [query] is maintained as nodes come and go, rather than
/// invalidated and rebuilt, so a query can never go stale and never has to be
/// recomputed. That is only affordable because every mutation runs through
/// this one type.
final class _Children {
  List<Node>? _nodes;
  Map<Type, _Index<Node>>? _indexes;

  /// These nodes, in [Node.priority] order.
  List<Node> get nodes => _nodes ?? const [];

  /// The nodes of type [T], in [Node.priority] order.
  ///
  /// Kept up to date as nodes come and go, so repeated calls cost nothing and
  /// allocate nothing. The first call for a given [T] pays one pass to build
  /// its index.
  Iterable<T> query<T extends Node>() {
    final indexes = _indexes ??= {};
    final existing = indexes[T];

    if (existing != null) {
      return (existing as _Index<T>).nodes;
    }

    final index = _Index<T>();

    for (final node in nodes) {
      if (node is T) index.nodes.add(node);
    }

    indexes[T] = index;
    return index.nodes;
  }

  /// Adds [node] at its [Node.priority] position, and to every index that
  /// accepts it.
  void add(Node node) {
    _insert(_nodes ??= [], node);

    final indexes = _indexes;
    if (indexes == null) return;

    for (final index in indexes.values) {
      if (index.accepts(node)) {
        _insert(index.nodes, node);
      }
    }
  }

  /// Removes [node] from this egg and every index holding it, reporting
  /// whether it was here at all.
  bool remove(Node node) {
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

  /// Moves [node] to its current [Node.priority] position, here and in every
  /// index holding it.
  void reorder(Node node) {
    if (remove(node)) add(node);
  }

  /// Inserts [node] into [nodes], keeping it ordered by [Node.priority]. Ties
  /// go after the nodes already there.
  static void _insert(List<Node> nodes, Node node) {
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

/// One type's view of an [_Children], holding every node of type [T].
final class _Index<T extends Node> {
  final List<T> nodes = [];

  /// Whether [node] belongs in [nodes].
  bool accepts(Node node) => node is T;
}
