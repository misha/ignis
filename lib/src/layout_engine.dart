import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:ignis/src/extensions.dart';
import 'package:ignis/src/layout_constraints.dart';
import 'package:ignis/src/layout_flex.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/owners/anchor_owner.dart';
import 'package:ignis/src/owners/position_owner.dart';

/// Something a layout algorithm can measure, position, and allocate space to.
mixin Measurable implements PositionOwner, AnchorOwner {
  /// This item's size.
  Vector2 get size;

  /// This item's width.
  double get width => size.x;

  /// This item's height.
  double get height => size.y;

  /// This item's size under [constraints], laying itself out first if possible.
  ///
  /// Defaults to [size] for items that can't lay themselves out any further.
  Vector2 measure(LayoutConstraints constraints) => size;

  /// How a flex layout shares its leftover main-axis space with this item.
  ///
  /// Defaults to [LayoutFlex.none] (meaning a fixed, non-flexible space).
  LayoutFlex get flex => .none;

  /// Whether a flex layout can resize this item at all.
  ///
  /// Defaults to false.
  bool get canResize => false;
}

/// A standalone set of layout algorithms, operating on [Measurable] items.
final class LayoutEngine {
  const LayoutEngine._();

  /// Measures every item against the same [childConstraints], tracks the
  /// largest extent, then places each item via [computeOffset].
  static Vector2 stack({
    required List<Measurable> items,
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

    final selfSize = computeSelfSize(items.length, largest);

    for (var i = 0; i < items.length; i++) {
      place(items[i], computeOffset(selfSize, sizes[i]));
    }

    return selfSize;
  }

  /// Measures non-flex items, distributes remaining main-axis space to flex
  /// items, then positions everyone.
  static Vector2 flex({
    required Axis direction,
    required LayoutConstraints constraints,
    required List<Measurable> items,
    required MainAxisAlignment mainAxisAlignment,
    required CrossAxisAlignment crossAxisAlignment,
    required MainAxisSize mainAxisSize,
    required bool reverse,
    required double spacing,
  }) {
    final crossAxis = flipAxis(direction);
    final maxMain = constraints.max.axis(direction);
    final canFlex = maxMain.isFinite;
    final crossMax = constraints.max.axis(crossAxis);
    final fillCross = crossAxisAlignment == .stretch;
    final childCount = items.length;

    assert(
      canFlex ||
          !items.any(
            (item) =>
                item.flex.factor > 0 && //
                (mainAxisSize == .max || item.flex.fit == .tight),
          ),
      'Layout has an unbounded main axis with a flexible item that demands a tight or'
      'max-forced space. Bound the axis, or use MainAxisSize.min with loose-fit items.',
    );

    // Pass 1: lay out every non-flex item. If the main axis is unbounded,
    // every item (flex or not) is treated as non-flex here.
    final sizes = List<Vector2?>.filled(childCount, null);
    var totalFlex = 0;
    var consumedMain = spacing * math.max(0, childCount - 1);
    var maxCross = 0.0;

    for (var i = 0; i < childCount; i++) {
      final item = items[i];

      if (canFlex && item.flex.factor > 0) {
        totalFlex += item.flex.factor;
        continue;
      }

      final childConstraints = LayoutConstraints(
        min: direction.toVector2(main: 0, cross: fillCross ? crossMax : 0),
        max: direction.toVector2(main: double.infinity, cross: crossMax),
      );

      final size = item.measure(childConstraints);
      sizes[i] = size;
      consumedMain += size.axis(direction);
      maxCross = math.max(maxCross, size.axis(crossAxis));
    }

    // Pass 2: distribute remaining main-axis space to flex items.
    if (canFlex && totalFlex > 0) {
      final spacePerFlex = math.max(0.0, maxMain - consumedMain) / totalFlex;

      for (var i = 0; i < childCount; i++) {
        final item = items[i];
        final flex = item.flex;
        if (flex.factor <= 0) continue;

        final maxExtent = spacePerFlex * flex.factor;
        final minExtent = flex.fit == .tight ? maxExtent : 0.0;
        final childConstraints = LayoutConstraints(
          min: direction.toVector2(main: minExtent, cross: fillCross ? crossMax : 0),
          max: direction.toVector2(main: maxExtent, cross: crossMax),
        );

        final size = item.measure(childConstraints);
        sizes[i] = size;
        consumedMain += size.axis(direction);
        maxCross = math.max(maxCross, size.axis(crossAxis));
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

    for (var i = 0; i < childCount; i++) {
      final item = items[i];
      final size = sizes[i]!;
      final itemMain = size.axis(direction);
      final itemCross = size.axis(crossAxis);
      final effectiveCross = item.canResize ? crossAxisAlignment : CrossAxisAlignment.start;
      final crossOffset = crossAxisOffset(effectiveCross, selfCross - itemCross);
      final mainPosition = reverse ? selfMain - cursor - itemMain : cursor;

      place(item, direction.toVector2(main: mainPosition, cross: crossOffset));
      cursor += itemMain + spacing + between;
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
