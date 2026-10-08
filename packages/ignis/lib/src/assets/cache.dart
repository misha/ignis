// SPDX-AI-Disclosure: none

import 'package:ignis/src/mailer.dart';
import 'package:ignis/src/message.dart';

/// Storage for arbitrary assets.
///
/// Every modification mails [CacheChange] to each subscriber.
class Cache with Mailer {
  final Map<String, dynamic> _entries = {};

  int get length => _entries.length;
  bool contains(String key) => _entries.containsKey(key);
  Iterable<String> get keys => _entries.keys;

  void add<T>(String key, T value) {
    _entries[key] = value;
    mail(CacheChange(this));
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
    if (contained) mail(CacheChange(this));
    return contained;
  }

  void clear() {
    if (_entries.isEmpty) return;
    _entries.clear();
    mail(CacheChange(this));
  }
}

/// Emitted whenever [cache] is modified.
final class CacheChange extends Message {
  final Cache cache;

  const CacheChange(this.cache);
}
