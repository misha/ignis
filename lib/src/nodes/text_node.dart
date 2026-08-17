import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:ignis/src/extensions.dart';
import 'package:ignis/src/layout/layout_constraints.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/sized_node.dart';

class TextNode extends SizedNode {
  /// The default style used when no [style] is provided.
  static const DEFAULT_STYLE = TextStyle(
    color: Color(0xFFFFFFFF),
    fontFamily: 'Arial',
    fontSize: 10,
  );

  TextPainter? _painter;
  bool _dirty = true;
  Vector2 _size = .zero;
  LayoutConstraints _constraints = const .unbounded();

  @visibleForTesting
  TextPainter get painter => _painter!;

  /// This node's size, as measured from its text. Zero until it first builds.
  ///
  /// Reading it lays the text out if anything has changed, so the size is
  /// current for layout, anchoring, and hit testing alike.
  @override
  Vector2 get size {
    _reflow();
    return _size;
  }

  String _text;
  TextStyle _style;
  TextAlign _textAlign;
  TextDirection _textDirection;

  TextNode({
    String? text,
    TextStyle? style,
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
       _style = style ?? DEFAULT_STYLE,
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

  /// The style used to draw the text.
  TextStyle get style => _style;

  set style(TextStyle style) {
    if (_style == style) return;
    _style = style;
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

    _size = painter.size.toVector2();
    _dirty = false;
  }
}
