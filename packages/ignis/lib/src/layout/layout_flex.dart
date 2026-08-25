// SPDX-AI-Disclosure: ai-assisted

import 'package:flutter/rendering.dart' show FlexFit;

/// The share of a flex layout's leftover main-axis space an item asks for,
/// and what it does with the space it gets.
///
/// The two travel together because [fit] means nothing without a [factor] to
/// claim space in the first place.
final class LayoutFlex {
  /// How many shares of the leftover space this item asks for. 0 asks for
  /// none, leaving the item at whatever size it chooses.
  final int factor;

  /// Whether this item must fill the space it is given, or may stay smaller.
  final FlexFit fit;

  const LayoutFlex._(this.factor, this.fit);

  /// No share of the leftover space: a fixed, non-flexible item.
  static const LayoutFlex none = LayoutFlex._(0, .loose);

  /// [factor] shares of the leftover space, filling every bit of what it
  /// gets. Defaults to 1 share.
  const LayoutFlex.expanded([int? factor])
    : assert(factor == null || factor > 0, 'Use LayoutFlex.none to ask for no space.'),
      factor = factor ?? 1,
      fit = .tight;

  /// [factor] shares of the leftover space, free to stay smaller than that.
  /// Defaults to 1 share.
  const LayoutFlex.flexible([int? factor])
    : assert(factor == null || factor > 0, 'Use LayoutFlex.none to ask for no space.'),
      factor = factor ?? 1,
      fit = .loose;

  @override
  String toString() => 'LayoutFlex($factor, $fit)';

  @override
  bool operator ==(Object other) =>
      other is LayoutFlex && //
      factor == other.factor &&
      fit == other.fit;

  @override
  int get hashCode => Object.hash(factor, fit);
}
