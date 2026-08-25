// SPDX-AI-Disclosure: none

part of 'core.dart';

/// Resolves to the nearest ancestor implementing [T].
///
/// Built once, where the host is constructed, and read wherever it is needed:
///
/// ```dart
/// late final _target = Target<AngleOwner>(this);
///
/// AngleOwner get target => _target.value;
/// ```
///
/// The host resolves it on mount and drops it whenever its ancestry changes,
/// so a node moved under a new parent finds the new one on its next read.
/// There is nothing to call and nothing to keep in sync.
class Target<T> {
  final Node _host;
  T? _value;

  Target(this._host) {
    _host._track(this);
  }

  /// The nearest ancestor implementing [T].
  ///
  /// Throws a [StateError] if the host is not mounted, or if nothing in its
  /// ancestry implements [T].
  T get value => _value ??= _find();

  T _find() {
    if (!_host.isMounted) {
      throw StateError('Cannot resolve $T because ${_host.runtimeType} is not mounted.');
    }

    final found = _host.ancestors.whereType<T>().firstOrNull;

    if (found == null) {
      throw StateError('${_host.runtimeType} has no ancestor implementing $T.');
    }

    return found;
  }

  void _resolve() => _value ??= _find();

  void _invalidate() => _value = null;
}
