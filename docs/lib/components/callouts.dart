import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:jaspr_content/theme.dart';

/// The four registers the README established, as markdown components.
///
/// `<Why>` explains why a decision went the way it did, and
/// `<Lineage from="Godot">` credits where an idea came from. Anything that fits
/// neither is ordinary prose.
class Callouts extends CustomComponentBase {
  Callouts();

  @override
  final Pattern pattern = RegExp(r'Why|Lineage');

  @override
  Component apply(String name, Map<String, String> attributes, Component? child) {
    final label = switch (name) {
      'Lineage' => 'From ${attributes['from'] ?? 'elsewhere'}',
      final other => other,
    };

    return div(classes: 'aside aside-${name.toLowerCase()}', [
      span(classes: 'aside-label', [.text(label)]),
      div(classes: 'aside-body', [?child]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.aside', [
      css('&').styles(
        padding: .symmetric(vertical: 0.75.rem, horizontal: 1.rem),
        margin: .only(top: 1.25.rem, bottom: 1.25.rem),
        border: .only(left: BorderSide(width: 3.px, color: ContentColors.primary)),
        radius: .only(topRight: .circular(0.375.rem), bottomRight: .circular(0.375.rem)),
      ),
      css('.aside-label').styles(
        display: .block,
        margin: .only(bottom: 0.25.rem),
        color: ContentColors.primary,
        fontSize: 0.75.rem,
        fontWeight: .w600,
        textTransform: .upperCase,
        letterSpacing: 0.05.em,
      ),
      css('.aside-body > p:first-child').styles(margin: .zero),
      css('.aside-body > p:last-child').styles(margin: .zero),
    ]),
  ];
}
