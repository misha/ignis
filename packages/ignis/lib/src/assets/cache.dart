// SPDX-AI-Disclosure: none

import 'package:ignis/src/core.dart';

/// Storage for arbitrary assets.
class Cache {
  final Map<String, dynamic> _entries = {};

  /// Emitted whenever the cache is modified.
  final onChanged = Signal0();

  int get length => _entries.length;
  bool contains(String key) => _entries.containsKey(key);
  Iterable<String> get keys => _entries.keys;

  void add<T>(String key, T value) {
    _entries[key] = value;
    onChanged.emit();
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
    if (contained) onChanged.emit();
    return contained;
  }

  void clear() {
    if (_entries.isEmpty) return;
    _entries.clear();
    onChanged.emit();
  }
}
