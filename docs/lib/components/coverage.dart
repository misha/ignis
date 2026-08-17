import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:jaspr_content/theme.dart';

/// `<Coverage/>`: how far along every page on the site is.
///
/// Derived from each page's `status`, so it cannot drift from the pages it
/// describes. Requires `eagerlyLoadAllPages`, or it only sees what has been
/// built so far.
class Coverage extends CustomComponentBase {
  Coverage();

  @override
  final Pattern pattern = 'Coverage';

  @override
  Component apply(String name, Map<String, String> attributes, Component? child) {
    return _CoverageTable();
  }

  @css
  static List<StyleRule> get styles => [
    css('.coverage', [
      css('&').styles(width: 100.percent),
      css('& td').styles(
        padding: .symmetric(vertical: 0.375.rem, horizontal: 0.5.rem),
        textAlign: .left,
      ),
      css('& th').styles(
        padding: .symmetric(vertical: 0.375.rem, horizontal: 0.5.rem),
        textAlign: .left,
      ),
      css('.coverage-status').styles(
        color: ContentColors.text,
        fontSize: 0.8125.rem,
      ),
    ]),
  ];
}

class _CoverageTable extends StatelessComponent {
  @override
  Component build(BuildContext context) {
    final rows = [
      for (final page in context.pages)
        (
          title: page.data.page['title'] as String? ?? page.url,
          url: page.url,
          lane: page.data.page['lane'] as String? ?? '',
          status: page.data.page['status'] as String? ?? 'stub',
        ),
    ]..sort((left, right) => left.url.compareTo(right.url));

    final complete = rows.where((row) => row.status == 'complete').length;

    return div([
      p([.text('$complete of ${rows.length} pages are complete.')]),
      table(classes: 'coverage', [
        thead([
          tr([
            th([.text('Page')]),
            th([.text('Lane')]),
            th([.text('Status')]),
          ]),
        ]),
        tbody([
          for (final row in rows)
            tr([
              td([
                a(href: row.url, [.text(row.title)]),
              ]),
              td(classes: 'coverage-status', [.text(row.lane)]),
              td(classes: 'coverage-status', [.text(row.status)]),
            ]),
        ]),
      ]),
    ]);
  }
}
