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

  @visibleForTesting
  late TextPainter painter;
  bool _dirty = true;
  Vector2 _size = .zero;
  LayoutConstraints _constraints = const .unbounded();

  /// This node's size, as measured from its text the last time anything about
  /// it changed. Zero until then.
  @override
  Vector2 get size => _size;

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
  }) {
    onMount(() {
      painter = .new(
        text: TextSpan(text: text, style: style ?? DEFAULT_STYLE),
        textAlign: textAlign ?? .start,
        textDirection: textDirection ?? .ltr,
      );

      // A remount builds a fresh painter, which has yet to be laid out.
      _dirty = true;
    });

    onUnmount(() {
      painter.dispose();
    });
  }

  /// The text to draw.
  String get text => painter.plainText;
  set text(String text) {
    if (this.text == text) return;
    painter.text = TextSpan(text: text, style: style);
    _dirty = true;
  }

  /// The style used to draw the text.
  TextStyle get style => painter.text?.style ?? DEFAULT_STYLE;
  set style(TextStyle style) {
    if (this.style == style) return;
    painter.text = TextSpan(text: text, style: style);
    _dirty = true;
  }

  /// How each line of text is aligned horizontally.
  TextAlign get textAlign => painter.textAlign;
  set textAlign(TextAlign textAlign) {
    if (this.textAlign == textAlign) return;
    painter.textAlign = textAlign;
    _dirty = true;
  }

  /// The direction in which the text flows.
  TextDirection get textDirection => painter.textDirection ?? .ltr;
  set textDirection(TextDirection textDirection) {
    if (this.textDirection == textDirection) return;
    painter.textDirection = textDirection;
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

    painter
      ..text = TextSpan(text: text, style: style)
      ..textAlign = textAlign
      ..textDirection = textDirection
      ..layout(minWidth: _constraints.min.x, maxWidth: _constraints.max.x);

    _size = painter.size.toVector2();
    _dirty = false;
  }

  @override
  void render(Canvas canvas) {
    // Laid out here, before the size is used for rendering.
    _reflow();
    super.render(canvas);
  }

  @override
  void renderAnchored(Canvas canvas) {
    painter.paint(canvas, .zero);
  }
}
