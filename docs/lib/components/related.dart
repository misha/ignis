import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:jaspr_content/theme.dart';

/// The pages this one leans on, listed before it starts.
///
/// A page lists their urls in its frontmatter and the layout renders this under
/// the title:
///
/// ```yaml
/// related: [/systems/assets, /concepts/nodes]
/// internals: [/internals/tree]
/// ```
///
/// What a page hands off is what fixes its own edges, so a reader meets the
/// handoffs before investing in the page rather than after. Each entry is
/// labelled with the title the target page gives itself, which is why the
/// frontmatter carries urls and no text of its own.
///
/// [Related.internals] renders the second list as its own row underneath, so a
/// reader can tell a page they may want next from a page about how this one
/// works underneath.
class Related extends StatelessComponent {
  final Page page;

  /// The frontmatter key holding this row's urls.
  final String field;

  /// The word this row is labelled with.
  final String label;

  const Related({
    required this.page,
    super.key,
  }) : field = 'related',
       label = 'Related';

  const Related.internals({
    required this.page,
    super.key,
  }) : field = 'internals',
       label = 'Internals';

  @override
  Component build(BuildContext context) {
    final listed = page.data.page[field];
    if (listed is! List || listed.isEmpty) return .fragment([]);

    final titles = {
      for (final other in context.pages)
        other.url: other.data.page['title']?.toString() ?? other.url,
    };

    return div(classes: 'related', [
      span(classes: 'related-label', [.text(label)]),
      ul([
        for (final url in listed.map((entry) => entry.toString()))
          li([
            a(href: url, [.text(titles[url] ?? url)]),
          ]),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.related', [
      css('&').styles(
        display: .flex,
        margin: .only(top: 1.rem, bottom: 2.rem),
        alignItems: .baseline,
        gap: .column(0.75.rem),
        raw: {'flex-wrap': 'wrap'},
      ),
      // Two rows read as one block: the space below belongs after the pair.
      css('&:has(+ .related)').styles(
        margin: .only(top: 1.rem, bottom: 0.rem),
      ),
      css('& + .related').styles(
        margin: .only(top: 0.25.rem, bottom: 2.rem),
      ),
      css('.related-label').styles(
        color: ContentColors.captions,
        fontFamily: ContentTheme.currentCodeFont,
        fontSize: 0.75.rem,
      ),
      css('ul').styles(
        display: .flex,
        padding: Padding.zero,
        margin: Margin.zero,
        gap: .new(row: 0.25.rem, column: 1.rem),
        listStyle: .none,
        raw: {'flex-wrap': 'wrap'},
      ),
      css('a').styles(fontSize: 0.875.rem),
    ]),
  ];
}
