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

/// What the label band reserves whether or not the register carries a mark, so
/// the registers differ by color and content and match everywhere else.
const Unit _MARK_SIZE = .rem(1.25);

/// The words a register wears, where its tag is not what the reader should see.
const _LABELS = {
  'Info': 'By the way...',
};

/// The four registers the README established, as markdown components.
///
/// `<Why>` explains why a decision went the way it did, and
/// `<Lineage from="Godot">` credits where an idea came from, wearing that
/// engine's own mark. Anything that fits neither is ordinary prose.
///
/// `<Info>` states something worth knowing that fits no other register.
///
/// `<Warning>` and `<Info>` are taken from the package's own `Callout`, which
/// draws a bordered box in a color the theme doesn't own. An aside opens off the
/// entry it belongs to; a box interrupts it. This must be registered ahead of
/// `Callout` for the tags to land here, since the first matching component wins.
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

  /// The label names the register, so the mark is what says where the idea
  /// came from. A source with no mark of its own goes without.
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
      // Uppercase caps sit high in a line box sized by the body's leading, so
      // trimming it to the text's own size lands the mark on the caps.
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
    // A warning carries the same shape as the others and separates by tone
    // alone: the ramp holds one hue, and this is the hottest step on it that
    // stays legible against the page.
    css('.aside-warning', [
      css('&').styles(
        border: .only(
          left: BorderSide(width: 3.px, color: FLARE),
        ),
      ),
      css('.aside-label').styles(color: FLARE),
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
