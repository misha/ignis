import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:jaspr_content/theme.dart';

import '../theme.dart';

/// The four registers the README established, as markdown components.
///
/// `<Why>` explains why a decision went the way it did, and
/// `<Lineage from="Godot">` credits where an idea came from. Anything that fits
/// neither is ordinary prose.
///
/// `<Warning>` is taken from the package's own `Callout`, which draws a bordered
/// box in a color the theme doesn't own. An aside opens off the entry it belongs
/// to; a box interrupts it. This must be registered ahead of `Callout` for the
/// tag to land here, since the first matching component wins.
class Callouts extends CustomComponentBase {
  Callouts();

  @override
  final Pattern pattern = RegExp(r'Why|Lineage|Warning');

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
        border: .only(
          left: BorderSide(width: 3.px, color: ContentColors.primary),
        ),
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
    // A warning carries the same shape as the others and separates by tone
    // alone: the ramp holds one hue, and this is the hottest step on it that
    // stays legible against the page.
    css('.aside-warning', [
      css('&').styles(
        border: .only(
          left: BorderSide(width: 3.px, color: Ember.burnt),
        ),
      ),
      css('.aside-label').styles(color: Ember.burnt),
    ]),
    // An aside inside a list entry belongs to that entry rather than to the
    // page, so it gives back most of the room it takes between paragraphs and
    // stops interrupting the run of entries around it.
    css('li > .aside').styles(
      padding: .symmetric(vertical: 0.5.rem, horizontal: 0.75.rem),
      margin: .only(top: 0.5.rem, bottom: 0.5.rem),
    ),
  ];
}
