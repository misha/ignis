/// Call to stop watching.
typedef Unwatch = void Function();

/// A named, type-safe message emitter.
sealed class Signal {
  const Signal();

  /// Subscribes to this signal, ignoring data.
  Unwatch watch(void Function() watcher);
}

/// A primitive that sends messages to watchers.
///
/// Reentrancy contract deliberately mirrors `ChangeNotifier.notifyListeners`.
/// Specifically:
///
///   - A watcher added during an emit never runs for that emit, but is visible
///     immediately (including to a nested emit started from within it).
///   - A watcher removed during an emit is tombstoned (nulled) in place right
///     away, so it stops running as of that removal even if the emit in
///     progress hasn't reached it yet.
///
/// Implementations are inlined for performance reasons.
class Signal0 extends Signal {
  List<void Function()?>? _watchers;
  int _depth = 0;
  bool _dirty = false;

  /// Subscribes to this signal, receiving data.
  Unwatch call(void Function() watcher) {
    (_watchers ??= []).add(watcher);
    return () => _remove(watcher);
  }

  @override
  Unwatch watch(void Function() watcher) {
    return call(watcher);
  }

  void _remove(void Function() watcher) {
    final watchers = _watchers;
    if (watchers == null) return;

    for (var i = 0; i < watchers.length; i += 1) {
      if (identical(watchers[i], watcher)) {
        if (_depth > 0) {
          watchers[i] = null;
          _dirty = true;
        } else {
          watchers.removeAt(i);
        }

        return;
      }
    }
  }

  /// Send an empty message to all watchers.
  void emit() {
    final watchers = _watchers;
    if (watchers == null || watchers.isEmpty) return;

    _depth += 1;
    final end = watchers.length;

    try {
      for (var i = 0; i < end; i += 1) {
        watchers[i]?.call();
      }
    } finally {
      _depth -= 1;

      if (_depth == 0 && _dirty) {
        _dirty = false;
        watchers.removeWhere((fn) => fn == null);
      }
    }
  }
}

/// A primitive that sends messages to watchers. See [Signal0] for details.
class Signal1<A> extends Signal {
  List<void Function(A)?>? _watchers;
  int _depth = 0;
  bool _dirty = false;

  /// Subscribes to this signal.
  Unwatch call(void Function(A) watcher) {
    (_watchers ??= []).add(watcher);
    return () => _remove(watcher);
  }

  @override
  Unwatch watch(void Function() watcher) {
    return call((A _) => watcher());
  }

  void _remove(void Function(A) watcher) {
    final watchers = _watchers;
    if (watchers == null) return;

    for (var i = 0; i < watchers.length; i += 1) {
      if (identical(watchers[i], watcher)) {
        if (_depth > 0) {
          watchers[i] = null;
          _dirty = true;
        } else {
          watchers.removeAt(i);
        }

        return;
      }
    }
  }

  /// Sends a message to all watchers.
  void emit(A a) {
    final watchers = _watchers;
    if (watchers == null || watchers.isEmpty) return;

    _depth += 1;
    final end = watchers.length;

    try {
      for (var i = 0; i < end; i += 1) {
        watchers[i]?.call(a);
      }
    } finally {
      _depth -= 1;

      if (_depth == 0 && _dirty) {
        _dirty = false;
        watchers.removeWhere((fn) => fn == null);
      }
    }
  }
}

/// A primitive that sends messages to watchers. See [Signal0] for details.
class Signal2<A, B> extends Signal {
  List<void Function(A, B)?>? _watchers;
  int _depth = 0;
  bool _dirty = false;

  /// Subscribes to this signal.
  Unwatch call(void Function(A, B) watcher) {
    (_watchers ??= []).add(watcher);
    return () => _remove(watcher);
  }

  @override
  Unwatch watch(void Function() watcher) {
    return call((A _, B _) => watcher());
  }

  void _remove(void Function(A, B) watcher) {
    final watchers = _watchers;
    if (watchers == null) return;

    for (var i = 0; i < watchers.length; i += 1) {
      if (identical(watchers[i], watcher)) {
        if (_depth > 0) {
          watchers[i] = null;
          _dirty = true;
        } else {
          watchers.removeAt(i);
        }

        return;
      }
    }
  }

  /// Sends a message to all watchers.
  void emit(A a, B b) {
    final watchers = _watchers;
    if (watchers == null || watchers.isEmpty) return;

    _depth += 1;
    final end = watchers.length;

    try {
      for (var i = 0; i < end; i += 1) {
        watchers[i]?.call(a, b);
      }
    } finally {
      _depth -= 1;

      if (_depth == 0 && _dirty) {
        _dirty = false;
        watchers.removeWhere((fn) => fn == null);
      }
    }
  }
}

/// A primitive that sends messages to watchers. See [Signal0] for details.
class Signal3<A, B, C> extends Signal {
  List<void Function(A, B, C)?>? _watchers;
  int _depth = 0;
  bool _dirty = false;

  /// Subscribes to this signal.
  Unwatch call(void Function(A, B, C) watcher) {
    (_watchers ??= []).add(watcher);
    return () => _remove(watcher);
  }

  @override
  Unwatch watch(void Function() watcher) {
    return call((A _, B _, C _) => watcher());
  }

  void _remove(void Function(A, B, C) watcher) {
    final watchers = _watchers;
    if (watchers == null) return;

    for (var i = 0; i < watchers.length; i += 1) {
      if (identical(watchers[i], watcher)) {
        if (_depth > 0) {
          watchers[i] = null;
          _dirty = true;
        } else {
          watchers.removeAt(i);
        }

        return;
      }
    }
  }

  /// Sends a message to all watchers.
  void emit(A a, B b, C c) {
    final watchers = _watchers;
    if (watchers == null || watchers.isEmpty) return;
    _depth += 1;
    final count = watchers.length;

    try {
      for (var i = 0; i < count; i += 1) {
        watchers[i]?.call(a, b, c);
      }
    } finally {
      _depth -= 1;

      if (_depth == 0 && _dirty) {
        _dirty = false;
        watchers.removeWhere((fn) => fn == null);
      }
    }
  }
}
