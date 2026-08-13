import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:ignis/src/extensions.dart';
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

  @override
  Vector2 get size => painter.size.toVector2();

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

  /// Updates [size] with the latest text parameters.
  ///
  /// Automatically called when rendering.
  void layout() {
    if (_dirty) {
      painter
        ..text = TextSpan(text: text, style: style)
        ..textAlign = textAlign
        ..textDirection = textDirection
        ..layout();

      _dirty = false;
    }
  }

  @override
  @mustCallSuper
  void render(Canvas canvas) {
    // Laid out here, before the size is used for rendering.
    layout();
    super.render(canvas);
  }

  @override
  void renderAnchored(Canvas canvas) {
    painter.paint(canvas, .zero);
  }
}
