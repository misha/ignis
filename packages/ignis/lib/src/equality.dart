import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

/// Implements same value equality, including float/NaN edge cases.
@internal
final class SameValueEquality implements Equality<Object?> {
  const SameValueEquality();

  @override
  bool equals(Object? a, Object? b) {
    if (a is num && b is num) {
      // NaN never equals itself, so two of them have to be paired directly.
      if (a.isNaN && b.isNaN) return true;

      // 0.0 and -0.0 are equal, but they are not the same key.
      if (a == 0 && b == 0) return a.isNegative == b.isNegative;
    }

    return a == b;
  }

  @override
  int hash(Object? e) {
    if (e is num && e.isNaN) return 0;
    return e.hashCode;
  }

  @override
  bool isValidKey(Object? o) => true;
}
