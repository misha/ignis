import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/components/code_block.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:jaspr_content/theme.dart';
import 'package:syntax_highlight_lite/syntax_highlight_lite.dart' as hl;

import '../colors.dart';
import '../source.dart';
import '../theme.dart';
import 'scene_demo.dart';

/// `<Demo name="..."/>`: a live scene, beside the source that runs it.
///
/// The name resolves to a file here and to a `#region` of the same name inside
/// it, so the code on the page is cut from the code that ran. A name with no
/// scene behind it renders as a placeholder saying so.
class Demo extends CustomComponentBase {
  Demo();

  /// The demos with a scene behind them, by the file their region lives in.
  static const built = {
    'spinner': 'overview.dart',
    'node-priority-order': 'nodes.dart',
    'node-priority-lifted': 'nodes.dart',
    'node-priority-nested': 'nodes.dart',
    'node-enabled': 'nodes.dart',
    'collision-pair': 'collisions.dart',
    'collision-active': 'collisions.dart',
    'collision-spin': 'collisions.dart',
    'collision-layer': 'collisions.dart',
    'collision-balls': 'collisions.dart',
    'debug-wireframes': 'debugging.dart',
    'sprite-still': 'sprites.dart',
    'sprite-animation': 'sprites.dart',
    'sprite-layers': 'sprites.dart',
    'sprite-rows': 'sprites.dart',
    'sprite-keys': 'sprites.dart',
    'sprite-rates': 'sprites.dart',
    'sprite-partial': 'sprites.dart',
    'sprite-tiles': 'sprites.dart',
    'sprite-timed': 'sprites.dart',
    'sprite-speed': 'sprites.dart',
    'sprite-group': 'sprites.dart',
    'sprite-signals': 'sprites.dart',
    'sprite-finish': 'sprites.dart',
    'transitions-cut': 'transitions.dart',
    'transitions-curtain': 'transitions.dart',
    'transitions-wipe': 'transitions.dart',
    'transitions-slide': 'transitions.dart',
    'transitions-fade': 'transitions.dart',
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

    // `<Demo name="..." hero/>`: the scene alone, floated beside the prose that
    // follows it, for a page to open on.
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
      // Start-aligned, so the scene keeps its square instead of stretching to
      // the code.
      css('&').styles(
        display: .grid,
        margin: .only(top: 1.5.rem, bottom: 1.5.rem),
        alignItems: .start,
        gap: .new(row: 0.75.rem, column: 1.rem),
        raw: {'grid-template-columns': 'minmax(0, 1fr) ${DEMO_EMBEDDED_SIZE.toInt()}px'},
      ),
      // The same gap in both columns lines the caption up with the file name.
      css('.demo-stage, .demo-source').styles(
        display: .flex,
        minWidth: Unit.zero,
        flexDirection: .column,
        gap: .column(0.375.rem),
      ),
      css('.code-block').styles(margin: Margin.zero),
      // `scrollbar-*` for Firefox, `::-webkit-*` below for the rest. Dark
      // neutrals, since the block is dark in either mode.
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
        backgroundColor: BORDER,
      ),
      css('pre:hover::-webkit-scrollbar-thumb').styles(
        backgroundColor: DIM,
      ),
      css('.demo-hint, .demo-origin').styles(
        color: IgnisTokens.muted,
        fontFamily: ContentTheme.currentCodeFont,
        fontSize: 0.75.rem,
      ),
    ]),
    // A hero floats right at its own width, with the opening paragraph beside
    // it.
    css('.content .demo-hero', [
      css('&').styles(
        width: DEMO_EMBEDDED_SIZE.px,
        margin: .only(left: 1.5.rem, bottom: 1.rem),
        raw: {'float': 'right'},
      ),
      css('.demo-hint').styles(
        display: .block,
        margin: .only(top: 0.375.rem),
        color: IgnisTokens.muted,
        fontFamily: ContentTheme.currentCodeFont,
        fontSize: 0.75.rem,
      ),
    ]),
    // Narrow: stack the scene under its source, and unfloat the hero.
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
