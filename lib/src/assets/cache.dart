import 'package:flutter/foundation.dart';

/// Storage for arbitrary assets.
///
/// A key may be *derived* from another, as in `hero.png#32,32` for a
/// spritesheet cut out of `hero.png`. Replacing the value at a key evicts
/// everything derived from it, so live asset changes invalidate the entries
/// built on top of them.
///
/// Every mutation notifies listeners exactly once, so consumers holding on to
/// what they retrieved can re-resolve it.
class Cache extends ChangeNotifier {
  /// Separates a base key from the parameters of a key derived from it.
  static const String separator = '#';

  /// The key for an entry derived from [key] with the given [parameters].
  static String derive(String key, String parameters) => '$key$separator$parameters';

  final Map<String, dynamic> _entries = {};

  int get length => _entries.length;
  bool contains(String key) => _entries.containsKey(key);
  Iterable<String> get keys => _entries.keys;

  void add<T>(String key, T value) {
    final replaced = contains(key);
    _entries[key] = value;
    if (replaced) _evictDerived(key);
    notifyListeners();
  }

  T retrieve<T>(String key) {
    if (!contains(key)) {
      throw StateError('Cache key "$key" does not contain data.');
    }

    final data = _entries[key];

    if (data is! T) {
      throw StateError(
        'Cache key "$key" did not contain an instance of $T. '
        'The actual type was ${data.runtimeType}.',
      );
    }

    return data;
  }

  bool evict(String key) {
    final contained = contains(key);
    _entries.remove(key);
    if (contained) notifyListeners();
    return contained;
  }

  /// Evicts every entry derived from [key], returning how many were removed.
  int evictDerived(String key) {
    final evicted = _evictDerived(key);
    if (evicted > 0) notifyListeners();
    return evicted;
  }

  int _evictDerived(String key) {
    final prefix = '$key$separator';

    final derived = [
      for (final entry in _entries.keys) //
        if (entry.startsWith(prefix)) //
          entry,
    ];

    for (final entry in derived) {
      _entries.remove(entry);
    }

    return derived.length;
  }

  void clear() {
    if (_entries.isEmpty) return;
    _entries.clear();
    notifyListeners();
  }
}
