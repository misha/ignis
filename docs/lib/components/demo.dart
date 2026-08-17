import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:jaspr_content/theme.dart';

/// `<Demo name="..."/>`: the slot a live scene will occupy.
///
/// Every demo on the site resolves through this one component, so adding a
/// scene costs a registry entry rather than a bespoke component, a `@Import`
/// shim, and a registration. The registry is empty until the harness lands;
/// until then a slot renders as a placeholder naming what belongs there.
class Demo extends CustomComponentBase {
  Demo();

  /// Scene builders by name. Stage 3 fills this in.
  static final Map<String, Component Function()> registry = {};

  @override
  final Pattern pattern = 'Demo';

  @override
  Component apply(String name, Map<String, String> attributes, Component? child) {
    final demo = attributes['name'] ?? '';
    final builder = registry[demo];

    if (builder != null) return builder();

    return div(classes: 'demo-slot', [
      span(classes: 'demo-slot-name', [.text(demo)]),
      span([.text('This scene has not been built yet.')]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.demo-slot', [
      css('&').styles(
        display: .flex,
        height: 200.px,
        padding: .all(1.rem),
        margin: .only(top: 1.5.rem, bottom: 1.5.rem),
        border: .all(width: 1.px, style: .dashed, color: ContentColors.hr),
        radius: .circular(0.5.rem),
        flexDirection: .column,
        justifyContent: .center,
        alignItems: .center,
        gap: .column(0.25.rem),
        color: ContentColors.text,
        fontSize: 0.8125.rem,
      ),
      css('.demo-slot-name').styles(
        fontFamily: ContentTheme.currentCodeFont,
        fontWeight: .w600,
      ),
    ]),
  ];
}
