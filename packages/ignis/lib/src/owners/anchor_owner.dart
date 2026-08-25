// SPDX-AI-Disclosure: none

import 'package:ignis/src/anchor.dart';

/// Something with an anchor.
abstract interface class AnchorOwner {
  Anchor get anchor;
  set anchor(Anchor value);

  /// Boxes an anchor.
  static AnchorOwner box([Anchor? anchor]) => _AnchorBox(anchor ?? .topLeft);
}

final class _AnchorBox implements AnchorOwner {
  @override
  Anchor anchor;

  _AnchorBox(this.anchor);
}
