// SPDX-AI-Disclosure: ai-assisted

import 'package:flutter/painting.dart';
import 'package:ignis/src/core.dart';

/// Holds the base [TextStyle] every descendant `TextNode` extends.
///
/// Styles merge downward: the style in effect at any node is its nearest
/// ancestor's, extended by its own. A style with `inherit: false` replaces
/// the inherited one instead.
class TextStyleNode extends Node {
  /// Emitted when [style] changes.
  final onStyleChange = Signal0();

  late final _target = Target<TextStyleNode?>(this);

  TextStyle _style;
  TextStyle? _resolved;

  TextStyleNode({
    required this._style,
    super.enabled,
    super.priority,
    super.children,
  });

  /// The style in effect at this node: the nearest ancestor's, extended by
  /// this node's own.
  TextStyle get style => _resolved ??= _target.value?.style.merge(_style) ?? _style;

  set style(TextStyle style) {
    if (_style == style) return;
    _style = style;
    _resolved = null;
    onStyleChange.emit();
  }

  @override
  void build() {
    super.build();
    _resolved = null;

    _target.value?.onStyleChange(() {
      _resolved = null;
      onStyleChange.emit();
    });
  }
}
