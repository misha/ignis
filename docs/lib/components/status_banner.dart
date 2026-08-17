import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:jaspr_content/theme.dart';

/// Says out loud how finished a page is.
///
/// The site ships at whatever depth it has reached, so every page that has not
/// reached its category floor admits it rather than reading as authoritative.
/// A `complete` page renders nothing.
class StatusBanner extends StatelessComponent {
  const StatusBanner({required this.page, super.key});

  final Page page;

  @override
  Component build(BuildContext context) {
    final status = page.data.page['status'];

    final message = switch (status) {
      'stub' => 'Stub. This page claims a topic and nothing more yet.',
      'partial' => 'Partial. What is here is accurate, but the page is below its depth floor.',
      _ => null,
    };

    if (message == null) return .fragment([]);

    return div(classes: 'status status-$status', [.text(message)]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.status', [
      css('&').styles(
        padding: .symmetric(vertical: 0.5.rem, horizontal: 0.875.rem),
        margin: .only(bottom: 1.5.rem),
        border: .all(width: 1.px, color: ContentColors.hr),
        radius: .circular(0.375.rem),
        color: ContentColors.text,
        fontSize: 0.8125.rem,
      ),
    ]),
  ];
}
