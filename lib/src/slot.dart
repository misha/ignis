part of 'core.dart';

/// One child declared by [Node.add] inside a pass, and the keys deciding
/// whether the next pass keeps it.
final class _Slot {
  final Node node;
  final List<Object?> keys;

  const _Slot(this.node, this.keys);
}

/// Whether two key lists mean the same thing, and so whether the child they
/// guard may be kept.
bool _sameKeys(List<Object?> a, List<Object?> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;

  for (var i = 0; i < a.length; i += 1) {
    final left = a[i];
    final right = b[i];

    if (left is num && right is num) {
      // NaN never equals itself, so two of them have to be paired directly.
      if (left.isNaN && right.isNaN) continue;

      // 0.0 and -0.0 are equal, but they are not the same key.
      if (left == 0 && right == 0) {
        if (left.isNegative != right.isNegative) return false;
        continue;
      }
    }

    if (left != right) return false;
  }

  return true;
}
