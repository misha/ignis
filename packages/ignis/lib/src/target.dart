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
///
/// A nullable [T] makes the ancestor optional: [value] is null while the host
/// is unmounted or has no such ancestor, instead of throwing.
class Target<T> {
  final Node _host;
  T? _value;

  Target(Node host) : _host = host {
    _host._track(this);
  }

  /// The node this target resolves from.
  @protected
  Node get host => _host;

  /// The nearest ancestor implementing [T].
  ///
  /// Throws a [StateError] if the host is not mounted, or if nothing in its
  /// ancestry implements [T], unless [T] is nullable.
  T get value => _value ??= _find();

  T _find() {
    if (!_host.isMounted) {
      if (null is T) return null as T;
      throw StateError('Cannot resolve $T because ${_host.runtimeType} is not mounted.');
    }

    final found = _host.ancestors.whereType<T>().firstOrNull;

    if (found == null && null is! T) {
      throw StateError('${_host.runtimeType} has no ancestor implementing $T.');
    }

    return found as T;
  }

  void _resolve() => _value ??= _find();

  void _invalidate() => _value = null;
}
