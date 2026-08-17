import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/components/code_block.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:jaspr_content/theme.dart';
import 'package:syntax_highlight_lite/syntax_highlight_lite.dart' as hl;

import '../source.dart';
import '../theme.dart';
import 'scene_demo.dart';

/// `<Demo name="..."/>`: a live scene, beside the source that runs it.
///
/// The name resolves to a file here and to a `#region` of the same name inside
/// it, so the code on the page is cut from the code that ran. Adding a scene
/// costs a line here and one in the client's own registry, rather than a
/// bespoke component, an `@Import` shim, and a registration. A name with no
/// scene behind it yet renders as a placeholder saying so.
class Demo extends CustomComponentBase {
  Demo();

  /// The demos with a scene behind them, by the file their region lives in.
  static const built = {
    'sprite-still': 'sprites.dart',
    'sprite-animation': 'sprites.dart',
    'sprite-layers': 'sprites.dart',
    'sprite-split': 'sprites.dart',
    'sprite-signals': 'sprites.dart',
    'sprite-finish': 'sprites.dart',
  };

  static hl.Highlighter? _dart;

  /// The same highlighter the site's fenced code blocks use.
  static hl.Highlighter get _highlighter {
    if (_dart case final highlighter?) return highlighter;
    hl.Highlighter.initialize(['dart']);
    return _dart = hl.Highlighter(language: 'dart', theme: ignisCodeTheme);
  }

  @override
  final Pattern pattern = 'Demo';

  @override
  Component apply(String name, Map<String, String> attributes, Component? child) {
    final demo = attributes['name'] ?? '';
    final file = built[demo];

    if (file == null) {
      return div(classes: 'demo-slot', [
        span(classes: 'demo-slot-name', [.text(demo)]),
        span([.text('This scene has not been built yet.')]),
      ]);
    }

    final hint = attributes['hint'];

    // `<Demo name="..." hero/>`: the scene on its own, with no code and no
    // title, for a page to open on. It floats beside the prose that follows it,
    // so it is written above that prose rather than under it.
    if (attributes.containsKey('hero')) {
      return div(classes: 'demo-hero', [
        SceneDemo(name: demo),
        if (hint != null) span(classes: 'demo-hint', [.text(hint)]),
      ]);
    }

    final source = DemoSource.cut(file, demo);

    return div(classes: 'demo', [
      div(classes: 'demo-source', [
        CodeBlock.from(source: source.code, highlighter: _highlighter),
        a(href: source.url, classes: 'demo-origin', [.text(file)]),
      ]),
      div(classes: 'demo-stage', [
        SceneDemo(name: demo),
        if (hint != null) span(classes: 'demo-hint', [.text(hint)]),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    // Scoped by `.content`, since the package's own `pre` rules are emitted
    // after ours and would win the tie at equal specificity.
    css('.content .demo', [
      // The code takes whatever height it needs and the scene keeps its square
      // beside it, aligned to the first line rather than stretched to match.
      css('&').styles(
        display: .grid,
        margin: .only(top: 1.5.rem, bottom: 1.5.rem),
        alignItems: .start,
        gap: .new(row: 0.75.rem, column: 1.rem),
        raw: {'grid-template-columns': 'minmax(0, 1fr) ${DEMO_EMBEDDED_SIZE.toInt()}px'},
      ),
      // Both columns are stacks with the same gap, so the caption under the
      // scene sits on the same line as the file name under the code.
      css('.demo-stage, .demo-source').styles(
        display: .flex,
        minWidth: Unit.zero,
        flexDirection: .column,
        gap: .column(0.375.rem),
      ),
      css('.code-block').styles(margin: Margin.zero),
      // Firefox takes the scrollbar from these two; the ones below are for
      // everything else. Both sit against a block that is dark in either mode,
      // so they name the dark neutrals rather than the theme's tokens.
      css('pre').styles(
        margin: Margin.zero,
        overflow: .auto,
        raw: {
          'scrollbar-width': 'thin',
          'scrollbar-color': '#2E2823 transparent',
        },
      ),
      css('pre::-webkit-scrollbar').styles(
        width: 0.5.rem,
        height: 0.5.rem,
      ),
      css('pre::-webkit-scrollbar-track').styles(backgroundColor: Colors.transparent),
      css('pre::-webkit-scrollbar-thumb').styles(
        radius: .circular(0.25.rem),
        backgroundColor: const Color('#2E2823'),
      ),
      css('pre:hover::-webkit-scrollbar-thumb').styles(
        backgroundColor: const Color('#6B6156'),
      ),
      css('.demo-hint, .demo-origin').styles(
        color: IgnisColors.muted,
        fontFamily: ContentTheme.currentCodeFont,
        fontSize: 0.75.rem,
      ),
    ]),
    // A hero carries no source, so it keeps its square and lets the opening
    // paragraph run beside it. A float and a width, and nothing else: the
    // scene and its caption are two blocks, and stack as such.
    css('.content .demo-hero', [
      css('&').styles(
        width: DEMO_EMBEDDED_SIZE.px,
        margin: .only(left: 1.5.rem, bottom: 1.rem),
        raw: {'float': 'right'},
      ),
      css('.demo-hint').styles(
        display: .block,
        margin: .only(top: 0.375.rem),
        color: IgnisColors.muted,
        fontFamily: ContentTheme.currentCodeFont,
        fontSize: 0.75.rem,
      ),
    ]),
    // One column is not enough for two, so the scene goes under its source,
    // and the hero stops making room it no longer has.
    css.media(MediaQuery.screen(maxWidth: 60.rem), [
      css('.demo').styles(raw: {'grid-template-columns': 'minmax(0, 1fr)'}),
      css('.content .demo-hero').styles(
        width: 100.percent,
        margin: .only(left: Unit.zero, bottom: 1.rem),
        raw: {'float': 'none'},
      ),
    ]),
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
