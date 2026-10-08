import 'package:flutter/foundation.dart';

/// A copy-on-write (COW) set, lovingly termed a *cow*.
///
/// Once the set is shared, it is never written again. The next write creates a
/// copy instead. In this implementation, [share] hands out the set, and
/// iterating over the set implicitly shares it. The only permitted mutations
/// are [add] and [remove].
///
/// Items are compared by identity and kept in insertion order.
@internal
final class Cow<T> extends Iterable<T> {
  /// The actual items in the set.
  Set<T> _items = .identity();

  /// Whether [_items] has been shared since it was last copied.
  bool _shared = false;

  /// The number of items, without sharing the set.
  @override
  int get length => _items.length;

  @override
  bool get isEmpty => _items.isEmpty;

  @override
  bool get isNotEmpty => _items.isNotEmpty;

  @override
  bool contains(Object? element) => _items.contains(element);

  /// Walks the set in insertion order.
  ///
  /// Per the COW contract, the set is guaranteed to never be written again.
  @override
  Iterator<T> get iterator => share().iterator;

  /// Hands out the set, to be read by the caller.
  ///
  /// Per the COW contract, the set is guaranteed to never be written again.
  Set<T> share() {
    _shared = true;
    return _items;
  }

  /// Adds [item], reporting whether it was not already here.
  bool add(T item) => _mutate().add(item);

  /// Removes [item], reporting whether it was here.
  bool remove(T item) => _mutate().remove(item);

  /// Hands out the items, to be written by the caller.
  ///
  /// Per the COW contract, this method copies the set if it has been shared.
  Set<T> _mutate() {
    if (_shared) {
      _shared = false;
      _items = .identity()..addAll(_items);
    }

    return _items;
  }
}
