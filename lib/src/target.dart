import 'package:ignis/src/core.dart';

/// Resolves to the nearest ancestor implementing [T].
class Target<T> {
  final Node _host;
  T? _value;

  /// The resolved ancestor, or null before the host has ever built.
  T? get value => _value;

  Target(this._host);

  /// Re-resolves against the host's current ancestors, and drops the result
  /// again when the host unmounts or rebuilds.
  void resolve() {
    _value = _host.ancestors.whereType<T>().firstOrNull;
    assert(_value != null, 'Must have an ancestor implementing $T.');
    _host.trash(() => _value = null);
  }
}
