import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:ignis/src/anchor.dart';
import 'package:ignis/src/layout_item.dart';
import 'package:ignis/src/extensions.dart';
import 'package:ignis/src/layout_constraints.dart';
import 'package:ignis/src/math.dart';

/// A standalone set of layout algorithms, operating on [LayoutItem] items.
abstract final class LayoutEngine {
  /// Sizes a region to [targetWidth]/[targetHeight] - or to its largest item
  /// plus [padding] where either is null - then places every item inside it
  /// at [alignment].
  ///
  /// ## Example (no alignment)
  ///
  /// Let's say you have a 100x60 region with 10 of padding and no alignment,
  /// holding one resizable item.
  ///
  ///     +----------------------------------------+
  ///     |                                        |
  ///     |    +--------------------------------+  |
  ///     |    |              item              |  |
  ///     |    +--------------------------------+  |
  ///     |                                        |
  ///     +----------------------------------------+
  ///     0   10                              90 100
  ///
  /// The steps are as follows:
  ///
  ///   1. Narrow the constraints. The padding leaves an 80x40 interior, and
  ///      nothing loosens it, so its minimum carries through.
  ///   2. Measure every item against that. Forced to fill, the item reports
  ///      80x40.
  ///   3. Size the region. With no target it shrink-wraps to the largest item
  ///      plus padding, landing on 100x60.
  ///   4. Place every item on the padded origin, (10, 10).
  ///
  /// ## Example (alignment)
  ///
  /// Now the same region, aligned at (0.5, 0.5), holding one 20x20 item.
  ///
  ///     +----------------------------------------+
  ///     |                                        |
  ///     |                +------+                |
  ///     |                | item |                |
  ///     |                +------+                |
  ///     |                                        |
  ///     +----------------------------------------+
  ///     0                40      60            100
  ///
  /// The steps are as follows:
  ///
  ///   1. Narrow the constraints. The padding leaves an 80x40 interior, and
  ///      aligning loosens it, so the item may come back smaller.
  ///   2. Measure every item against that. The item reports 20x20.
  ///   3. Size the region. Aligning asks for room to align within, so each
  ///      bounded axis is taken whole, landing on 100x60.
  ///   4. Place every item. That leaves 60x20 of room inside the padding, and
  ///      half of it puts the item at (40, 20).
  static Vector2 box({
    required Iterable<LayoutItem> items,
    required LayoutConstraints constraints,
    required double? targetWidth,
    required double? targetHeight,
    required EdgeInsets padding,
    required Anchor? alignment,
  }) {
    final LayoutConstraints region;

    if (targetWidth != null || targetHeight != null) {
      region = LayoutConstraints(
        min: .new(targetWidth ?? 0, targetHeight ?? 0),
        max: .new(targetWidth ?? double.infinity, targetHeight ?? double.infinity),
      ).enforce(constraints);
    } else {
      region = constraints;
    }

    var itemConstraints = region;

    if (padding != .zero) {
      itemConstraints = itemConstraints.deflate(padding);
    }

    if (alignment != null) {
      itemConstraints = itemConstraints.loosen();
    }

    // Measure. An item reports a size in its own space, so it is measured
    // against constraints carried into that space and compared on the extent
    // that size occupies back out here.
    final largest = MVector2.zero();
    final extent = MVector2.zero();

    for (final item in items) {
      item.layout(itemConstraints.descale(item.scale));

      extent
        ..setFrom(item.size)
        ..multiply(item.scale)
        ..absolute();

      largest.max(extent);
    }

    // Size. An alignment asks for room to align within, so it takes every
    // bounded axis whole; an unbounded one has no room to ask for. [region] is
    // already tight on any targeted axis, so a target still wins either way.
    final fill = alignment != null;
    final size = region.constrain(
      fill && region.hasBoundedWidth ? region.max.x : largest.x + padding.horizontal,
      fill && region.hasBoundedHeight ? region.max.y : largest.y + padding.vertical,
    );

    // Place. Nothing was kept from the measure pass: [LayoutItem] guarantees
    // an item still reports the size it just measured at. An unaligned item
    // multiplies the leftover room by zero, landing on the padded origin.
    final anchor = alignment ?? .topLeft;
    final innerWidth = size.x - padding.horizontal;
    final innerHeight = size.y - padding.vertical;

    for (final item in items) {
      extent
        ..setFrom(item.size)
        ..multiply(item.scale)
        ..absolute();

      place(
        item,
        .new(
          padding.left + (innerWidth - extent.x) * anchor.x,
          padding.top + (innerHeight - extent.y) * anchor.y,
        ),
      );
    }

    return size;
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
    required Iterable<LayoutItem> items,
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
    // Only a scaled item pays for one of its own, via [LayoutConstraints.descale].
    final looseConstraints = LayoutConstraints(
      min: direction.toVector2(main: 0, cross: fillCross ? crossMax : 0),
      max: direction.toVector2(main: double.infinity, cross: crossMax),
    );

    var index = 0;

    for (final item in items) {
      if (canFlex && item.flex.factor > 0) {
        totalFlex += item.flex.factor;
      } else {
        final scale = item.scale;
        item.layout(looseConstraints.descale(scale));
        final size = item.size;
        mains[index] = (size.axis(direction) * scale.axis(direction)).abs();
        crosses[index] = (size.axis(crossAxis) * scale.axis(crossAxis)).abs();
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

          final scale = item.scale;
          item.layout(childConstraints.descale(scale));
          final size = item.size;
          mains[index] = (size.axis(direction) * scale.axis(direction)).abs();
          crosses[index] = (size.axis(crossAxis) * scale.axis(crossAxis)).abs();
          consumedMain += mains[index];
          maxCross = math.max(maxCross, crosses[index]);
        }

        index += 1;
      }
    }

    final idealMain = mainAxisSize == .max && canFlex ? maxMain : consumedMain;
    final selfSize = switch (direction) {
      .horizontal => constraints.constrain(idealMain, maxCross),
      .vertical => constraints.constrain(maxCross, idealMain),
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
  /// honoring [item]'s own anchor and scale.
  static void place(LayoutItem item, Vector2 position) {
    final size = item.size;
    final scale = item.scale;
    final anchor = item.anchor;

    // The anchor offset is applied in the item's own space, so it arrives here
    // scaled. A flipped axis grows the other way, which puts its anchor on the
    // opposite edge. Without that, the content lands outside its own space.
    final anchorX = scale.x < 0 ? anchor.x - 1 : anchor.x;
    final anchorY = scale.y < 0 ? anchor.y - 1 : anchor.y;

    item.position.setValues(
      anchorX * size.x * scale.x + position.x,
      anchorY * size.y * scale.y + position.y,
    );
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
