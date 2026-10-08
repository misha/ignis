// SPDX-AI-Disclosure: none

part of 'core.dart';

/// A flat list kept in [compare] order, alongside an index per queried type.
///
/// Each index built by [query] is maintained as items come and go, rather than
/// invalidated and rebuilt, so a query can never go stale and never has to be
/// recomputed. That is only affordable because every mutation runs through
/// this one type.
final class _Children<E> {
  final Comparator<E> compare;

  List<E>? _items;
  Map<Type, _Index<E>>? _indexes;

  _Children(this.compare);

  static _Children<Entity> entities() {
    return _Children((a, b) {
      return a._priority.compareTo(b._priority);
    });
  }

  static _Children<Component> components() {
    return _Children((a, b) {
      return a._priority.compareTo(b._priority);
    });
  }

  /// These items, in [compare] order.
  List<E> get items => _items ?? const [];

  /// The items of type [T], in [compare] order.
  ///
  /// Kept up to date as items come and go, so repeated calls cost nothing and
  /// allocate nothing. The first call for a given [T] pays one pass to build
  /// its index.
  Iterable<T> query<T extends E>() {
    final indexes = _indexes ??= {};
    final existing = indexes[T];

    if (existing != null) {
      return (existing as _Index<T>).items;
    }

    final index = _Index<T>();

    for (final item in items) {
      if (item is T) index.items.add(item);
    }

    indexes[T] = index;
    return index.items;
  }

  /// Inserts [item] in [compare] order, after any it ties with, here and in
  /// every index that accepts it.
  void insert(E item) {
    _place(_items ??= [], item);

    final indexes = _indexes;

    if (indexes != null) {
      for (final index in indexes.values) {
        if (index.accepts(item)) {
          _place(index.items, item);
        }
      }
    }
  }

  /// Moves [item] to its current [compare] position, here and in every index
  /// holding it.
  void reorder(E item) {
    if (remove(item)) insert(item);
  }

  /// Removes [item] from these items and every index holding it, reporting
  /// whether it was here at all.
  bool remove(E item) {
    if (_items?.remove(item) != true) return false;

    final indexes = _indexes;

    if (indexes != null) {
      for (final index in indexes.values) {
        if (index.accepts(item)) {
          index.items.remove(item);
        }
      }
    }

    return true;
  }

  /// Inserts [item] into [items] at its [compare] position, after any it ties
  /// with.
  void _place(List<E> items, E item) {
    var low = 0;
    var high = items.length;

    while (low < high) {
      final middle = (low + high) >> 1;

      if (compare(items[middle], item) <= 0) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }

    items.insert(low, item);
  }
}

/// One type's view of a [_Children], holding every item of type [T].
final class _Index<T> {
  final List<T> items = [];

  /// Whether [item] belongs in [items].
  bool accepts(Object? item) => item is T;
}
