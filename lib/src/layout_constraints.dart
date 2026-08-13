import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:ignis/src/math.dart';

final _ZERO = Vector2.zero();

/// The range of sizes a layout item may choose from when it lays itself out.
///
/// Mirrors Flutter's `BoxConstraints`, but implemented using [Vector2].
final class LayoutConstraints {
  /// The smallest size satisfying these constraints.
  final Vector2 min;

  /// The largest size satisfying these constraints. Either component may be
  /// [double.infinity], meaning unbounded in that axis.
  final Vector2 max;

  LayoutConstraints({
    required Vector2 min,
    required Vector2 max,
  }) : assert(
         min.x <= max.x && min.y <= max.y,
         'min must be <= max in both axes.',
       ),
       min = min.clone(),
       max = max.clone();

  /// Exactly [size] in both axes.
  LayoutConstraints.tight(Vector2 size) : min = size.clone(), max = size.clone();

  /// Zero to [size] in both axes.
  LayoutConstraints.loose(Vector2 size) : min = .zero(), max = size.clone();

  /// No minimum; unbounded maximum, in both axes.
  LayoutConstraints.unbounded() : min = .zero(), max = .all(double.infinity);

  /// The size closest to [size] that satisfies these constraints.
  /// TODO: Benchmark this?
  Vector2 satisfy(Vector2 size) => size.clamp(.new(min.x, max.x), .new(min.y, max.y));

  /// The largest size satisfying these constraints.
  Vector2 get biggest => max.clone();

  /// The smallest size satisfying these constraints.
  Vector2 get smallest => min.clone();

  /// Whether [max]'s x component is finite.
  bool get hasBoundedWidth => max.x.isFinite;

  /// Whether [max]'s y component is finite.
  bool get hasBoundedHeight => max.y.isFinite;

  /// Whether [min] and [max] are equal in both axes.
  bool get isTight => min.x >= max.x && min.y >= max.y;

  /// These constraints with [min] cleared to zero, keeping [max].
  LayoutConstraints loosen() => .new(min: .zero(), max: max);

  /// These constraints with [padding] subtracted from [min] and [max],
  /// clamping both so neither drops below zero and [max] never ends up
  /// below the deflated [min].
  LayoutConstraints deflate(EdgeInsets padding) {
    final deflatedMin = min.clone();
    deflatedMin.mutate()
      ..x -= padding.horizontal
      ..y -= padding.vertical
      ..max(_ZERO);

    final deflatedMax = max.clone();
    deflatedMax.mutate()
      ..x -= padding.horizontal
      ..y -= padding.vertical
      ..max(deflatedMin);

    return .new(min: deflatedMin, max: deflatedMax);
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
