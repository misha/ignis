import 'package:ignis/src/anchor.dart';

/// Something with an anchor.
abstract interface class AnchorOwner {
  Anchor get anchor;

  /// Boxes an anchor.
  static AnchorOwner box([Anchor? anchor]) => _AnchorBox(anchor ?? .topLeft());
}

final class _AnchorBox implements AnchorOwner {
  @override
  final Anchor anchor;

  _AnchorBox(this.anchor);
}
