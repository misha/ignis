import 'package:ignis/src/anchor.dart';
import 'package:ignis/src/layout/layout_constraints.dart';
import 'package:ignis/src/layout/layout_flex.dart';
import 'package:ignis/src/math.dart';

/// Something a layout algorithm can lay out, position, and allocate space to.
abstract interface class LayoutItem {
  /// This item's position. Must be mutable for the engine to place.
  MVector2 get position;

  /// Where this item's area sits relative to [position].
  Anchor get anchor;

  /// This item's size.
  Vector2 get size;

  /// This item's scale.
  Vector2 get scale;

  /// This item's width.
  double get width;

  /// This item's height.
  double get height;

  /// How a flex layout shares its leftover main-axis space with this item.
  ///
  /// An item asking for no share returns [LayoutFlex.none], leaving it a
  /// fixed, non-flexible space.
  LayoutFlex get flex;

  /// Lays this item out under [constraints], leaving [size] reporting the
  /// result.
  ///
  /// An item that can't lay itself out any further does nothing at all,
  /// keeping whatever intrinsic [size] it already had.
  ///
  /// Returns nothing on purpose: [size] is the only channel, so an algorithm
  /// needing sizes in a later pass reads them back off the item instead of
  /// keeping its own copies.
  void layout(LayoutConstraints constraints);
}
