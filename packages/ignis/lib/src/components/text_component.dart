// SPDX-AI-Disclosure: none

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:ignis/src/anchor.dart';
import 'package:ignis/src/core.dart';
import 'package:ignis/src/extensions.dart';
import 'package:ignis/src/geometry.dart';
import 'package:ignis/src/globals.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/message.dart';
import 'package:ignis/src/shape.dart';
import 'package:ignis/src/transform.dart';

class TextComponent extends Component with Transform, Geometry {
  /// The style beneath every [TextComponent], in effect when nothing is declared.
  static const DEFAULT_STYLE = TextStyle(
    color: Color(0xFFFFFFFF),
    fontFamily: 'Arial',
    fontSize: 10,
  );

  TextPainter? _painter;
  Shape _shape = const Rectangle(.zero);

  @visibleForTesting
  TextPainter get painter => _painter!;

  /// This component's area, as measured from its text. Empty until it first
  /// builds.
  ///
  /// Reading it lays the text out if anything has changed, so the size is
  /// current for anchoring.
  @override
  Shape get shape {
    final painter = _painter;
    if (painter == null) return _shape; // Nothing to measure with until it builds.
    painter.layout();
    final size = painter.size;

    if (size.width != _shape.width || //
        size.height != _shape.height) {
      _shape = Rectangle(size.toVector2());
    }

    return _shape;
  }

  @override
  set shape(Shape value) {
    throw UnsupportedError('A TextComponent is sized by its text.');
  }

  String _text;

  /// The text to draw.
  String get text => _text;

  set text(String text) {
    if (_text == text) return;
    _text = text;
    _painter?.text = TextSpan(
      text: text,
      style: style,
    );
  }

  TextStyle? _style;
  TextStyle? _resolved;
  TextAlign _textAlign;
  TextDirection _textDirection;

  /// The style in effect: this component's own, extending [DEFAULT_STYLE].
  TextStyle get style => _resolved ??= DEFAULT_STYLE.merge(_style);

  /// Sets this component's own style. Null falls back to [DEFAULT_STYLE] alone.
  set style(TextStyle? style) {
    if (_style == style) return;
    _style = style;
    _resolved = null;
    _painter?.text = TextSpan(
      text: _text,
      style: this.style,
    );
  }

  /// How each line of text is aligned horizontally.
  TextAlign get textAlign => _textAlign;

  set textAlign(TextAlign textAlign) {
    if (_textAlign == textAlign) return;
    _textAlign = textAlign;
    _painter?.textAlign = textAlign;
  }

  /// The direction in which the text flows.
  TextDirection get textDirection => _textDirection;

  set textDirection(TextDirection textDirection) {
    if (_textDirection == textDirection) return;
    _textDirection = textDirection;
    _painter?.textDirection = textDirection;
  }

  TextComponent({
    String? text,
    this._style,
    TextAlign? textAlign,
    TextDirection? textDirection,
    Vector2? position,
    Vector2? scale,
    double? angle,
    Anchor? anchor,
    super.id,
    super.enabled,
  }) : _text = text ?? '',
       _textAlign = textAlign ?? .start,
       _textDirection = textDirection ?? .ltr {
    if (position != null) this.position.setFrom(position);
    if (scale != null) this.scale.setFrom(scale);
    if (angle != null) this.angle = angle;
    if (anchor != null) this.anchor = anchor;
  }

  @override
  void process(Message message) {
    super.process(message);

    switch (message) {
      case Build():
        _painter = TextPainter(
          text: TextSpan(
            text: _text,
            style: style,
          ),
          textAlign: _textAlign,
          textDirection: _textDirection,
        );

      case Destroy():
        _painter?.dispose();
        _painter = null;
    }
  }

  @override
  void render(Canvas canvas) {
    painter.layout();
    canvas.save();
    canvas.transform(renderTransform);
    painter.paint(canvas, .zero);
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
