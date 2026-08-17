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
/// ```
///
/// What a page hands off is what fixes its own edges, so a reader meets the
/// handoffs before investing in the page rather than after. Each entry is
/// labelled with the title the target page gives itself, which is why the
/// frontmatter carries urls and no text of its own.
class Related extends StatelessComponent {
  final Page page;

  const Related({
    required this.page,
    super.key,
  });

  @override
  Component build(BuildContext context) {
    final listed = page.data.page['related'];
    if (listed is! List || listed.isEmpty) return .fragment([]);

    final titles = {
      for (final other in context.pages)
        other.url: other.data.page['title']?.toString() ?? other.url,
    };

    return div(classes: 'related', [
      span(classes: 'related-label', [.text('Related')]),
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
