// SPDX-AI-Disclosure: none

import 'package:flutter/foundation.dart';

/// A specialized copy-on-write (COW) list, lovingly termed a *cow*.
///
/// Once the list is shared, it is never written again. The next write creates a
/// copy instead. In this implementation, iterating over the list implicitly
/// shares it. The only permitted mutations are [insert] and [remove].
///
/// Additionally, the [query] method provides a live, updating view over the
/// list for any particular type. Queries targeting the same type are handed the
/// exact same view. Internally, mutations maintain all queries in parallel,
/// each in the same order as the list.
///
/// Combined, this data structure forms an efficient substrate for an immediate
/// mode tree that elegantly sidesteps concurrent modification errors, without
/// resorting to frame-delayed operations.
@internal
final class Cow<T> extends Iterable<T> {
  /// The actual items in the list.
  List<T> _items = [];

  /// Whether [_items] has been shared since it was last copied.
  bool _shared = false;

  /// Every [query] made so far, by type.
  Map<Type, CowView<T>>? _views;

  /// The number of items, without sharing the list.
  @override
  int get length => _items.length;

  /// The item at [index], without sharing the list.
  T operator [](int index) => _items[index];

  @override
  bool get isEmpty => _items.isEmpty;

  @override
  bool get isNotEmpty => _items.isNotEmpty;

  @override
  T get first => _items.first;

  @override
  T get last => _items.last;

  @override
  T elementAt(int index) => _items[index];

  @override
  bool contains(Object? element) => _items.contains(element);

  /// Walks the list in order.
  ///
  /// Per the COW contract, the list is guaranteed to never be written again.
  @override
  Iterator<T> get iterator {
    _shared = true;
    return _items.iterator;
  }

  /// Walks the list in reverse order.
  ///
  /// Per the COW contract, the list is guaranteed to never be written again.
  Iterable<T> get reversed sync* {
    _shared = true;
    final items = _items;

    for (var i = items.length - 1; i >= 0; i -= 1) {
      yield items[i];
    }
  }

  /// Hands out the items, to be written by the caller.
  ///
  /// Per the COW contract, this method copies the list if it has been shared.
  ///
  /// The returned list must not be retained past a later iteration, or it risks
  /// concurrent modification. Call [_mutate] again for each new scope.
  List<T> _mutate() {
    if (_shared) {
      _shared = false;
      _items = List.of(_items);
    }

    return _items;
  }

  /// The items of type [S].
  ///
  /// Queries for the same [S] receive the same list.
  Cow<S> query<S extends T>() {
    final views = _views ??= {};
    final existing = views[S];

    if (existing != null) {
      return existing as Cow<S>;
    }

    final view = CowView<S>();
    final items = view._mutate();

    for (final item in _items) {
      if (item is S) {
        items.add(item);
      }
    }

    views[S] = view;
    return view;
  }

  /// Inserts [item] at [index] in this list.
  void insert(int index, T item) {
    final items = _mutate()..insert(index, item);
    final views = _views;
    if (views == null) return;

    for (final view in views.values) {
      if (!view._accepts(item)) continue;

      // Whatever this view holds from past index sits at its end.
      var position = view.length;

      for (var i = index + 1; i < items.length; i += 1) {
        if (view._accepts(items[i])) {
          position -= 1;
        }
      }

      view._mutate().insert(position, item);
    }
  }

  /// Removes [item] from this list.
  bool remove(T item) {
    if (!_remove(item)) return false;

    final views = _views;
    if (views == null) return true;

    for (final view in views.values) {
      if (view._accepts(item)) {
        view._remove(item);
      }
    }

    return true;
  }

  bool _remove(T item) {
    for (var i = 0; i < _items.length; i += 1) {
      if (identical(_items[i], item)) {
        _mutate().removeAt(i);
        return true;
      }
    }

    return false;
  }
}

/// The [Cow] of every item of type [S].
@internal
final class CowView<S> extends Cow<S> {
  /// Whether [item] belongs here.
  bool _accepts(Object? item) => item is S;
}
