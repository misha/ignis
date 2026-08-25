// SPDX-AI-Disclosure: none

import 'package:ignis/src/math.dart';

/// Something with a scale.
abstract interface class ScaleOwner {
  MVector2 get scale;

  /// Boxes a scale.
  static ScaleOwner box([MVector2? scale]) => _ScaleBox(scale ?? .all(1));
}

final class _ScaleBox implements ScaleOwner {
  @override
  final MVector2 scale;

  _ScaleBox(this.scale);
}
