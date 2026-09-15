import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:jaspr_content/theme.dart';

import '../colors.dart';

/// The mark each `<Lineage>` source wears.
const _MARKS = {
  'flame': '/images/lineage-flame.png',
  'godot': '/images/lineage-godot.svg',
};

/// The mark's size, and the label band's min-height, so marked and unmarked
/// registers align.
const Unit _MARK_SIZE = .rem(1.25);

/// Display text for registers whose tag differs from their label.
const _LABELS = {
  'Info': 'By the way...',
};

/// The four registers the README established, as markdown components.
///
/// `<Why>` gives the rationale for a decision. `<Lineage from="Godot">` credits
/// where an idea came from, wearing that engine's mark. `<Info>` states
/// something worth knowing. `<Warning>` flags what will bite.
///
/// `<Warning>` and `<Info>` are taken over from the package's own `Callout`,
/// which draws a bordered box in a color the theme does not own. This must be
/// registered ahead of `Callout`, since the first matching component wins.
class Callouts extends CustomComponentBase {
  Callouts();

  @override
  final Pattern pattern = RegExp(r'Why|Lineage|Warning|Info');

  @override
  Component apply(String name, Map<String, String> attributes, Component? child) {
    return div(classes: 'aside aside-${name.toLowerCase()}', [
      span(classes: 'aside-label', [
        ?_mark(attributes['from']),
        .text(_LABELS[name] ?? name),
      ]),
      div(classes: 'aside-body', [?child]),
    ]);
  }

  /// The mark for [source], or null if it has none.
  static Component? _mark(String? source) {
    if (source == null) return null;

    final path = _MARKS[source.toLowerCase()];
    if (path == null) return null;

    return img(src: path, alt: source, classes: 'aside-mark');
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
      // Line height trimmed to the text, so the mark lands on the caps.
      css('.aside-label').styles(
        display: .flex,
        minHeight: _MARK_SIZE,
        margin: .only(bottom: 0.5.rem),
        alignItems: .center,
        gap: .column(0.375.rem),
        color: ContentColors.primary,
        fontSize: 0.75.rem,
        fontWeight: .w600,
        textTransform: .upperCase,
        letterSpacing: 0.05.em,
        lineHeight: 1.em,
      ),
      // Content typography gives every `img` a 2em vertical margin, which at
      // the label's size is 24px of air the text-only registers never get.
      css('.aside-mark').styles(
        width: _MARK_SIZE,
        height: _MARK_SIZE,
        margin: .zero,
      ),
      css('.aside-body > p:first-child').styles(margin: .zero),
      css('.aside-body > p:last-child').styles(margin: .zero),
    ]),
    // Same shape, hotter rule: the hottest step still legible on the page.
    css('.aside-warning', [
      css('&').styles(
        border: .only(
          left: BorderSide(width: 3.px, color: FLARE),
        ),
      ),
      css('.aside-label').styles(color: FLARE),
    ]),
    // Tighter inside a list entry, where it belongs to the entry rather than
    // the page.
    css('li > .aside').styles(
      padding: .symmetric(vertical: 0.5.rem, horizontal: 0.75.rem),
      margin: .only(top: 0.5.rem, bottom: 0.5.rem),
    ),
  ];
}
