import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:jaspr_content/theme.dart';

/// Where `dart doc` publishes the engine.
const _API = '/api/ignis';

/// The block's anchor, for the table of contents.
const _ANCHOR = 'reference';

/// The symbols [page] lists in its frontmatter, in the order it lists them.
List<String> _symbols(Page page) {
  final listed = page.data.page['reference'];
  if (listed is! List) return const [];

  return [
    for (final symbol in listed) //
      symbol.toString(),
  ];
}

/// What a page put to work, linked to its entry in the API reference.
///
/// A page lists them in its frontmatter and the layout renders this underneath
/// it, so the prose never carries the links itself:
///
/// ```yaml
/// reference: [SpriteNode, SpriteImage, SpriteAnimation, SpriteSheet]
/// ```
///
/// List the major classes a reader constructs; every entry links to its `-class.html`.
class Reference extends StatelessComponent {
  final Page page;

  const Reference({
    required this.page,
    super.key,
  });

  @override
  Component build(BuildContext context) {
    final symbols = _symbols(page);
    if (symbols.isEmpty) return .fragment([]);

    return div(id: _ANCHOR, classes: 'reference', [
      span(classes: 'reference-label', [.text('Reference')]),
      ul([
        for (final symbol in symbols)
          li([
            a(href: '$_API/$symbol-class.html', [.text(symbol)]),
          ]),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.reference', [
      css('&').styles(
        padding: .only(top: 1.rem, bottom: 4.rem),
        margin: .only(top: 2.5.rem),
        border: .only(
          top: BorderSide(width: 1.px, color: ContentColors.hr),
        ),
      ),
      css('.reference-label').styles(
        display: .block,
        margin: .only(bottom: 0.5.rem),
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
      css('a').styles(
        fontFamily: ContentTheme.currentCodeFont,
        fontSize: 0.875.rem,
      ),
    ]),
  ];
}

/// Lists [Reference] in the table of contents, on the pages that carry one.
///
/// The layout injects [Reference] after every extension runs, so the generated
/// contents miss it. This appends its entry.
///
/// Must be applied after [TableOfContentsExtension], which replaces whatever
/// sits under 'toc' wholesale.
class ReferenceEntryExtension implements PageExtension {
  const ReferenceEntryExtension();

  @override
  Future<List<Node>> apply(Page page, List<Node> nodes) async {
    if (_symbols(page).isEmpty) return nodes;

    if (page.data['toc'] case final TableOfContents contents) {
      page.apply(
        data: {
          'toc': TableOfContents([
            ...contents.entries,
            TocEntry('Reference', _ANCHOR, []),
          ]),
        },
      );
    }

    return nodes;
  }
}
