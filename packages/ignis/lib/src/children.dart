// SPDX-AI-Disclosure: none

part of 'core.dart';

/// An entity's children: a flat list kept in [Entity.priority] order, alongside
/// an index per queried type.
///
/// Each index built by [query] is maintained as nodes come and go, rather than
/// invalidated and rebuilt, so a query can never go stale and never has to be
/// recomputed. That is only affordable because every mutation runs through
/// this one type.
final class _Children {
  List<Entity>? _entities;
  Map<Type, _Index<Entity>>? _indexes;

  /// These nodes, in [Entity.priority] order.
  List<Entity> get entities => _entities ?? const [];

  /// The nodes of type [T], in [Entity.priority] order.
  ///
  /// Kept up to date as nodes come and go, so repeated calls cost nothing and
  /// allocate nothing. The first call for a given [T] pays one pass to build
  /// its index.
  Iterable<T> query<T extends Entity>() {
    final indexes = _indexes ??= {};
    final existing = indexes[T];

    if (existing != null) {
      return (existing as _Index<T>).entities;
    }

    final index = _Index<T>();

    for (final entity in entities) {
      if (entity is T) index.entities.add(entity);
    }

    indexes[T] = index;
    return index.entities;
  }

  /// Adds [entity] at its [Entity.priority] position, and to every index that
  /// accepts it.
  void add(Entity entity) {
    _insert(_entities ??= [], entity);

    final indexes = _indexes;
    if (indexes == null) return;

    for (final index in indexes.values) {
      if (index.accepts(entity)) {
        _insert(index.entities, entity);
      }
    }
  }

  /// Removes [entity] from this egg and every index holding it, reporting
  /// whether it was here at all.
  bool remove(Entity entity) {
    if (_entities?.remove(entity) != true) return false;

    final indexes = _indexes;
    if (indexes == null) return true;

    for (final index in indexes.values) {
      if (index.accepts(entity)) {
        index.entities.remove(entity);
      }
    }

    return true;
  }

  /// Moves [entity] to its current [Entity.priority] position, here and in every
  /// index holding it.
  void reorder(Entity entity) {
    if (remove(entity)) add(entity);
  }

  /// Inserts [entity] into [entities], keeping it ordered by [Entity.priority]. Ties
  /// go after the nodes already there.
  static void _insert(List<Entity> entities, Entity entity) {
    var low = 0;
    var high = entities.length;

    while (low < high) {
      final middle = (low + high) >> 1;

      if (entities[middle].priority <= entity.priority) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }

    entities.insert(low, entity);
  }
}

/// One type's view of a [_Children], holding every node of type [T].
final class _Index<T extends Entity> {
  final List<T> entities = [];

  /// Whether [entity] belongs in [entities].
  bool accepts(Entity entity) => entity is T;
}
