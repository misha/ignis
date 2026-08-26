// SPDX-AI-Disclosure: none

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:ignis/src/core.dart';
import 'package:ignis/src/extensions.dart';
import 'package:ignis/src/layout/layout_constraints.dart';
import 'package:ignis/src/nodes/spatial_node.dart';
import 'package:ignis/src/nodes/text_style_node.dart';
import 'package:ignis/src/shape.dart';

class TextNode extends SpatialNode {
  /// The style beneath every [TextNode], in effect when nothing is declared.
  static const DEFAULT_STYLE = TextStyle(
    color: Color(0xFFFFFFFF),
    fontFamily: 'Arial',
    fontSize: 10,
  );

  TextPainter? _painter;
  bool _dirty = true;
  Shape _shape = const Rectangle(.zero);
  LayoutConstraints _constraints = const .unbounded();
  late final _target = Target<TextStyleNode?>(this);

  @visibleForTesting
  TextPainter get painter => _painter!;

  /// This node's area, as measured from its text. Empty until it first builds.
  ///
  /// Reading it lays the text out if anything has changed, so the size is
  /// current for layout, anchoring, and hit testing alike.
  @override
  Shape get shape {
    _reflow();
    return _shape;
  }

  String _text;
  TextStyle? _style;
  TextStyle? _resolved;
  TextAlign _textAlign;
  TextDirection _textDirection;

  TextNode({
    String? text,
    this._style,
    TextAlign? textAlign,
    TextDirection? textDirection,
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.enabled,
    super.priority,
    super.children,
  }) : _text = text ?? '',
       _textAlign = textAlign ?? .start,
       _textDirection = textDirection ?? .ltr;

  @override
  void build() {
    super.build();
    final painter = _painter = TextPainter(
      text: TextSpan(text: _text, style: _style),
      textAlign: _textAlign,
      textDirection: _textDirection,
    );

    trash(() {
      painter.dispose();
      _painter = null;
    });

    _target.value?.onStyleChange(() {
      _resolved = null;
      _dirty = true;
    });

    _resolved = null;
    _dirty = true;

    draw((canvas) {
      painter.paint(canvas, .zero);
    });
  }

  /// The text to draw.
  String get text => _text;

  set text(String text) {
    if (_text == text) return;
    _text = text;
    _dirty = true;
  }

  /// The style in effect: the nearest [TextStyleNode]'s, extended by this
  /// node's own.
  TextStyle get style => _resolved ??=
      DEFAULT_STYLE //
          .merge(_target.value?.style)
          .merge(_style);

  /// Sets this node's own style. Null falls back to the inherited style alone.
  set style(TextStyle? style) {
    if (_style == style) return;
    _style = style;
    _resolved = null;
    _dirty = true;
  }

  /// How each line of text is aligned horizontally.
  TextAlign get textAlign => _textAlign;

  set textAlign(TextAlign textAlign) {
    if (_textAlign == textAlign) return;
    _textAlign = textAlign;
    _dirty = true;
  }

  /// The direction in which the text flows.
  TextDirection get textDirection => _textDirection;

  set textDirection(TextDirection textDirection) {
    if (_textDirection == textDirection) return;
    _textDirection = textDirection;
    _dirty = true;
  }

  /// Wraps this node's text to fit [constraints], then takes its size from
  /// the result.
  ///
  /// Only the width is honored - text is never squeezed vertically, so a tall
  /// enough block overflows its constraints rather than clipping.
  @override
  void layout(LayoutConstraints constraints) {
    if (constraints != _constraints) {
      _constraints = constraints;
      _dirty = true;
    }

    _reflow();
  }

  /// Lays the painter out and stores the size it reports, if anything about
  /// the text or its constraints has changed since the last time.
  void _reflow() {
    if (!_dirty) return;
    final painter = _painter;
    if (painter == null) return; // Nothing to measure with until it builds.

    painter
      ..text = TextSpan(text: text, style: style)
      ..textAlign = textAlign
      ..textDirection = textDirection
      ..layout(minWidth: _constraints.min.x, maxWidth: _constraints.max.x);

    _shape = Rectangle(painter.size.toVector2());
    _dirty = false;
  }
}
