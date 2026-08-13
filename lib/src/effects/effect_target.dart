import 'package:ignis/src/node.dart';

/// Resolves to the nearest ancestor implementing [T], once [host] is mounted;
/// null before that, and after [host] is unmounted.
class EffectTarget<T> {
  T? _value;

  /// The resolved ancestor.
  T? get value => _value;

  EffectTarget(Node host) {
    host.onMount(() {
      _value = host.ancestors.whereType<T>().firstOrNull;
      assert(_value != null, 'Must have an ancestor implementing $T.');
    });

    host.onUnmount(() {
      _value = null;
    });
  }
}
