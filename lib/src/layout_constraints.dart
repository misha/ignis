import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:ignis/src/math.dart';

/// The range of sizes a layout item may choose from when it lays itself out.
///
/// Mirrors Flutter's `BoxConstraints`, but implemented using [Vector2].
final class LayoutConstraints {
  /// The smallest size satisfying these constraints.
  final Vector2 min;

  /// The largest size satisfying these constraints. Either component may be
  /// [double.infinity], meaning unbounded in that axis.
  final Vector2 max;

  const LayoutConstraints({
    required this.min,
    required this.max,
  }) : assert(
         min is! MVector2 && max is! MVector2,
         'min and max must be immutable. '
         'Copy mutable sizes with Vector2.copy first.',
       );

  /// Exactly [size] in both axes. Aliases [size] rather than copying, so it
  /// must already be immutable - this is checked with an assertion. Copy a
  /// mutable size with [Vector2.copy] first if needed.
  const LayoutConstraints.tight(Vector2 size)
    : assert(
        size is! MVector2,
        'size must be immutable. '
        'Copy it with Vector2.copy first.',
      ),
      min = size,
      max = size;

  /// Zero to [size] in both axes. Aliases [size] rather than copying, so it
  /// must already be immutable - this is checked with an assertion. Copy a
  /// mutable size with [Vector2.copy] first if needed.
  const LayoutConstraints.loose(Vector2 size)
    : assert(
        size is! MVector2,
        'size must be immutable. '
        'Copy it with Vector2.copy first.',
      ),
      min = .zero,
      max = size;

  /// No minimum; unbounded maximum, in both axes.
  const LayoutConstraints.unbounded() : min = .zero, max = const .all(double.infinity);

  /// The size closest to [size] that satisfies these constraints.
  ///
  /// TODO: Examine callers and see if this method can't be responsible for the
  ///   creation of the return vector, allowing it set it up via MVector2.
  Vector2 satisfy(Vector2 size) => size
      .clampedToX(min.x, max.x) //
      .clampedToY(min.y, max.y);

  /// Whether [max]'s x component is finite.
  bool get hasBoundedWidth => max.x.isFinite;

  /// Whether [max]'s y component is finite.
  bool get hasBoundedHeight => max.y.isFinite;

  /// Whether [min] and [max] are equal in both axes.
  bool get isTight => min.x >= max.x && min.y >= max.y;

  /// These constraints with [min] cleared to zero, keeping [max].
  LayoutConstraints loosen() => .new(min: .zero, max: max);

  /// These constraints with [padding] subtracted from [min] and [max],
  /// clamping both so neither drops below zero and [max] never ends up
  /// below the deflated [min].
  LayoutConstraints deflate(EdgeInsets padding) {
    final deflatedMin = MVector2.copy(min)
      ..x -= padding.horizontal
      ..y -= padding.vertical
      ..max(.zero);

    final deflatedMax = MVector2.copy(max)
      ..x -= padding.horizontal
      ..y -= padding.vertical
      ..max(deflatedMin);

    return .new(min: .copy(deflatedMin), max: .copy(deflatedMax));
  }

  @override
  String toString() => '$min -> $max';

  @override
  bool operator ==(Object other) =>
      other is LayoutConstraints && //
      min == other.min &&
      max == other.max;

  @override
  int get hashCode => Object.hash(min, max);
}
