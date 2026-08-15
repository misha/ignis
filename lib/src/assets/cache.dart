/// Storage for arbitrary assets.
class Cache {
  final Map<String, dynamic> _entries = {};

  int get length => _entries.length;
  bool contains(String key) => _entries.containsKey(key);
  Iterable<String> get keys => _entries.keys;

  void add<T>(String key, T value) {
    _entries[key] = value;
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
    return contained;
  }

  void clear() {
    _entries.clear();
  }
}
