import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:ignis/src/anchor.dart';
import 'package:ignis/src/extensions.dart';
import 'package:ignis/src/layout_constraints.dart';
import 'package:ignis/src/layout_flex.dart';
import 'package:ignis/src/math.dart';

/// Something a layout algorithm can measure, position, and allocate space to.
abstract interface class Measurable {
  /// This item's position. Must be mutable for the engine to place.
  MVector2 get position;

  /// Where this item's area sits relative to [position].
  Anchor get anchor;

  /// This item's size.
  Vector2 get size;

  /// This item's width.
  double get width;

  /// This item's height.
  double get height;

  /// How a flex layout shares its leftover main-axis space with this item.
  ///
  /// An item asking for no share returns [LayoutFlex.none], leaving it a
  /// fixed, non-flexible space.
  LayoutFlex get flex;

  /// This item's size under [constraints], laying itself out first if possible.
  ///
  /// An item that can't lay itself out any further returns [size], ignoring
  /// [constraints] entirely.
  Vector2 measure(LayoutConstraints constraints);
}

/// A standalone set of layout algorithms, operating on [Measurable] items.
final class LayoutEngine {
  const LayoutEngine._();

  /// Measures every item against the same [childConstraints], tracks the
  /// largest extent, then places each item via [computeOffset].
  static Vector2 stack({
    required Iterable<Measurable> items,
    required LayoutConstraints childConstraints,
    required Vector2 Function(int childCount, Vector2 largestChildSize) computeSelfSize,
    required Vector2 Function(Vector2 selfSize, Vector2 childSize) computeOffset,
  }) {
    final largest = MVector2.zero();
    final sizes = <Vector2>[];

    for (final item in items) {
      final size = item.measure(childConstraints);
      sizes.add(size);
      largest.max(size);
    }

    final selfSize = computeSelfSize(sizes.length, largest);
    var index = 0;

    for (final item in items) {
      place(item, computeOffset(selfSize, sizes[index]));
      index += 1;
    }

    return selfSize;
  }

  /// Measures non-flex items, distributes remaining main-axis space to flex
  /// items, then positions everyone in exactly three passes.
  ///
  /// ## Example
  ///
  /// Let's say you have a 100 wide row holding a 10px leaf and two items
  /// flexed 1 and 3, set to `MainAxisSize.max`.
  ///
  ///     +----+---------+---------------------------+
  ///     |leaf|  flex 1 |          flex 3           |
  ///     | 10 |   22.5  |           67.5            |
  ///     +----+---------+---------------------------+
  ///     0    10        32.5                      100
  ///
  /// The passes are as follows:
  ///
  ///   1. Measure everything that isn't flexed, against an unbounded main
  ///      axis. The leaf reports 10, consuming 10 of the row. The other two
  ///      are skipped, owing 4 shares between them.
  ///   2. Divide what's left. 90 across 4 shares is 22.5 each, so the flexed
  ///      items are measured against 22.5 and 67.5. A tight fit must fill its
  ///      share; a loose one may report back smaller.
  ///   3. Walk a cursor along the main axis, placing each item and advancing
  ///      by its extent plus [spacing], landing them at 0, 10 and 32.5.
  static Vector2 flex({
    required Axis direction,
    required LayoutConstraints constraints,
    required Iterable<Measurable> items,
    required MainAxisAlignment mainAxisAlignment,
    required CrossAxisAlignment crossAxisAlignment,
    required MainAxisSize mainAxisSize,
    required double spacing,
  }) {
    final crossAxis = flipAxis(direction);
    final maxMain = constraints.max.axis(direction);
    final canFlex = maxMain.isFinite;
    final crossMax = constraints.max.axis(crossAxis);
    final fillCross = crossAxisAlignment == .stretch;
    final childCount = items.length;

    // Flex divides whatever the main axis has left over, and an unbounded axis
    // never has a leftover. Pass 1 measures flexed items at their natural size
    // instead, which only holds up if nothing demanded to fill something.
    if (!canFlex) {
      assert(
        !items.any((item) => item.flex.factor > 0) || mainAxisSize == .min,
        'A flex with an unbounded main axis has no leftover space, so '
        'MainAxisSize.max has nothing to fill. Bound the main axis, or use '
        'MainAxisSize.min.',
      );

      assert(
        items.every((item) => item.flex.factor <= 0 || item.flex.fit == .loose),
        'A flex with an unbounded main axis has no share for FlexFit.tight to '
        'fill. Bound the main axis, or use LayoutFlex.flexible instead of '
        'LayoutFlex.expanded.',
      );
    }

    // Pass 1: lay out every non-flex item. If the main axis is unbounded,
    // every item (flex or not) is treated as non-flex here.
    //
    // Extents are kept as main/cross doubles rather than sizes, so passes 2
    // and 3 never re-derive them from an axis.
    final mains = List<double>.filled(childCount, 0);
    final crosses = List<double>.filled(childCount, 0);
    var totalFlex = 0;
    var consumedMain = spacing * math.max(0, childCount - 1);
    var maxCross = 0.0;

    // Identical for every item, so it is built once rather than per child.
    final looseConstraints = LayoutConstraints(
      min: direction.toVector2(main: 0, cross: fillCross ? crossMax : 0),
      max: direction.toVector2(main: double.infinity, cross: crossMax),
    );

    var index = 0;

    for (final item in items) {
      if (canFlex && item.flex.factor > 0) {
        totalFlex += item.flex.factor;
      } else {
        final size = item.measure(looseConstraints);
        mains[index] = size.axis(direction);
        crosses[index] = size.axis(crossAxis);
        consumedMain += mains[index];
        maxCross = math.max(maxCross, crosses[index]);
      }

      index += 1;
    }

    // Pass 2: distribute remaining main-axis space to flex items.
    if (canFlex && totalFlex > 0) {
      final spacePerFlex = math.max(0.0, maxMain - consumedMain) / totalFlex;

      index = 0;

      for (final item in items) {
        final flex = item.flex;

        if (flex.factor > 0) {
          final maxExtent = spacePerFlex * flex.factor;
          final minExtent = flex.fit == .tight ? maxExtent : 0.0;
          final childConstraints = LayoutConstraints(
            min: direction.toVector2(main: minExtent, cross: fillCross ? crossMax : 0),
            max: direction.toVector2(main: maxExtent, cross: crossMax),
          );

          final size = item.measure(childConstraints);
          mains[index] = size.axis(direction);
          crosses[index] = size.axis(crossAxis);
          consumedMain += mains[index];
          maxCross = math.max(maxCross, crosses[index]);
        }

        index += 1;
      }
    }

    final idealMain = mainAxisSize == .max && canFlex ? maxMain : consumedMain;
    final selfSize = switch (direction) {
      .horizontal => constraints.satisfy(idealMain, maxCross),
      .vertical => constraints.satisfy(maxCross, idealMain),
    };

    // Pass 3: position every item.
    final selfMain = selfSize.axis(direction);
    final selfCross = selfSize.axis(crossAxis);
    final freeMain = math.max(0.0, selfMain - consumedMain);
    final (leading, between) = distributeSpace(mainAxisAlignment, freeMain, childCount);

    var cursor = leading;

    index = 0;

    for (final item in items) {
      final crossOffset = crossAxisOffset(crossAxisAlignment, selfCross - crosses[index]);
      place(item, direction.toVector2(main: cursor, cross: crossOffset));
      cursor += mains[index] + spacing + between;
      index += 1;
    }

    return selfSize;
  }

  /// Positions [item] so its content's top-left corner lands at [position],
  /// honoring [item]'s own anchor.
  static void place(Measurable item, Vector2 position) {
    item.position
      ..setFrom(item.anchor)
      ..multiply(item.size)
      ..add(position);
  }

  /// The leading gap and the gap between each pair of adjacent items, for
  /// [freeSpace] distributed across [count] items per [alignment].
  static (double, double) distributeSpace(
    MainAxisAlignment alignment,
    double freeSpace,
    int count,
  ) {
    return switch (alignment) {
      .start => (0, 0),
      .end => (freeSpace, 0),
      .center => (freeSpace / 2, 0),
      .spaceBetween => (
        0,
        count > 1 ? freeSpace / (count - 1) : 0,
      ),
      .spaceAround => (
        count > 0 ? freeSpace / count / 2 : 0,
        count > 0 ? freeSpace / count : 0,
      ),
      .spaceEvenly => (
        count > 0 ? freeSpace / (count + 1) : 0,
        count > 0 ? freeSpace / (count + 1) : 0,
      ),
    };
  }

  /// The cross-axis offset for [freeSpace], per [alignment].
  static double crossAxisOffset(CrossAxisAlignment alignment, double freeSpace) {
    return switch (alignment) {
      .end => freeSpace,
      .center => freeSpace / 2,
      .start || .stretch || .baseline => 0,
    };
  }
}
