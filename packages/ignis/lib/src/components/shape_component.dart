// SPDX-AI-Disclosure: none

import 'dart:ui';

import 'package:ignis/src/anchor.dart';
import 'package:ignis/src/core.dart';
import 'package:ignis/src/geometry.dart';
import 'package:ignis/src/globals.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/palette.dart';
import 'package:ignis/src/shape.dart';
import 'package:ignis/src/transform.dart';

class ShapeComponent extends Component with Transform, Geometry {
  /// This component's registered paints.
  final Palette palette;

  /// The default paint.
  Paint get paint => palette.paint;

  ShapeComponent({
    required Shape shape,
    Vector2? position,
    Vector2? scale,
    double? angle,
    Anchor? anchor,
    Paint? paint,
    super.id,
    super.enabled,
  }) : palette = Palette(paint: paint) {
    this.shape = shape;
    if (position != null) this.position.setFrom(position);
    if (scale != null) this.scale.setFrom(scale);
    if (angle != null) this.angle = angle;
    if (anchor != null) this.anchor = anchor;
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.transform(renderTransform);
    palette.draw(canvas, shape.draw);
    canvas.restore();
  }

  @override
  void debugRender(Canvas canvas) {
    final debug = Ignis.debug;
    if (!debug.draws(.spatial)) return;
    canvas.save();
    canvas.transform(renderTransform);
    canvas.drawRect(shape.rect(), debug.paint);
    canvas.restore();
  }
}
