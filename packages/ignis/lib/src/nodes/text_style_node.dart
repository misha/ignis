// SPDX-AI-Disclosure: ai-assisted

import 'package:flutter/painting.dart';
import 'package:ignis/src/core.dart';
import 'package:ignis/src/mailer.dart';
import 'package:ignis/src/message.dart';

/// Holds the base [TextStyle] every descendant `TextNode` extends.
///
/// Styles merge downward: the style in effect at any node is its nearest
/// ancestor's, extended by its own. A style with `inherit: false` replaces
/// the inherited one instead.
///
/// Mails [TextStyleChange] whenever the style in effect here changes.
class TextStyleNode extends Node with Mailer {
  late final _target = Target<TextStyleNode?>(this);

  TextStyle _style;
  TextStyle? _resolved;

  TextStyleNode({
    required this._style,
    super.enabled,
    super.priority,
    super.children,
  });

  /// The style in effect at this node.
  TextStyle get style => _resolved ??= _target.value?.style.merge(_style) ?? _style;

  set style(TextStyle style) {
    if (_style == style) return;
    _style = style;
    _changed();
  }

  @override
  void process(Message message) {
    super.process(message);

    switch (message) {
      case Build():
        _resolved = null;
        _target.value?.subscribe(this);

      case TextStyleChange():
        _changed();

      case Destroy():
        _target.value?.unsubscribe(this);
    }
  }

  void _changed() {
    _resolved = null;
    mail(TextStyleChange(this));
  }
}

/// Mailed when the style in effect at [node] changes.
final class TextStyleChange extends Message {
  final TextStyleNode node;

  const TextStyleChange(this.node);
}
