import 'package:jaspr/dom.dart';
import 'package:jaspr_content/theme.dart';
import 'package:syntax_highlight_lite/syntax_highlight_lite.dart' as hl;

import 'colors.dart';

abstract final class IgnisTokens {
  static final surface = ColorToken('surface', INK);
  static final border = ColorToken('border', BORDER);
  static final muted = ColorToken('muted', GREY);
  static final primaryHi = ColorToken('primary-hi', SPARK);

  static const _background = ThemeColor(BACKGROUND);
  static const _text = ThemeColor(BRIGHT);
  static const _headings = ThemeColor(HEADINGS);
  static const _primary = ThemeColor(FLARE);

  static List<ColorToken> get all => [
    surface,
    border,
    muted,
    primaryHi,
    ContentColors.headings.apply(_headings),
    ContentColors.links.apply(_primary),
    ContentColors.bold.apply(_headings),
    ContentColors.quotes.apply(_text),
    ContentColors.quoteBorders.apply(_primary),
    ContentColors.captions.apply(muted),
    ContentColors.counters.apply(muted),
    ContentColors.lead.apply(muted),
    ContentColors.kbdShadows.apply(border),
    ContentColors.bullets.apply(_primary),
    ContentColors.hr.apply(border),
    ContentColors.thBorders.apply(border),
    ContentColors.tdBorders.apply(border),
    ContentColors.code.apply(const ThemeColor(GLOW)),
    ContentColors.kbd.apply(_headings),
    ContentColors.preBg.apply(const ThemeColor(INK)),
    ContentColors.preCode.apply(const ThemeColor(BRIGHT)),
  ];
}

/// The site theme.
ContentTheme get ignisTheme => ContentTheme(
  primary: IgnisTokens._primary,
  background: IgnisTokens._background,
  text: IgnisTokens._text,
  colors: IgnisTokens.all,
  font: FontFamily.list([
    FontFamily('EB Garamond'),
    FontFamilies.serif,
  ]),
  codeFont: FontFamily.list([
    FontFamily('iA Writer Mono'),
    FontFamilies.uiMonospace,
    FontFamilies.monospace,
  ]),
  typography: ContentTypography.base.apply(
    styles: Styles(lineHeight: 1.7.em),
    rules: [
      css('h1, h2, h3, h4').styles(
        color: ContentColors.headings,
        fontFamily: FontFamily('IM FELL Great Primer'),
        fontWeight: .w400,
        letterSpacing: 0.01.em,
      ),
    ],
  ),
);

/// Dart highlighting, drawn from the ramp. The artwork has one hue, so scopes
/// separate by lightness.
final ignisCodeTheme = hl.HighlighterTheme.fromConfiguration(
  '''
{"settings":[
  {"settings":{"foreground":"${BRIGHT.value}"}},
  {"scope":["comment","punctuation.definition.comment"],"settings":{"foreground":"${DIM.value}","fontStyle":"italic"}},
  {"scope":["keyword","storage","storage.type","keyword.control","modifier"],"settings":{"foreground":"${EMBER.value}"}},
  {"scope":["entity.name.type","entity.name.class","support.class","support.type"],"settings":{"foreground":"${FLARE.value}"}},
  {"scope":["string","string.quoted","constant.character"],"settings":{"foreground":"${FLARE.value}"}},
  {"scope":["constant.numeric","constant.language"],"settings":{"foreground":"${SPARK.value}"}},
  {"scope":["entity.name.function","support.function","meta.function-call"],"settings":{"foreground":"${SPARK.value}"}},
  {"scope":["variable","variable.parameter","meta.definition.variable"],"settings":{"foreground":"${BRIGHT.value}"}},
  {"scope":["keyword.operator","punctuation","meta.brace"],"settings":{"foreground":"${GREY.value}"}},
  {"scope":["meta.declaration.annotation","storage.type.annotation"],"settings":{"foreground":"${EMBER.value}"}}
]}''',
  hl.TextStyle(
    foreground: hl.Color(0xFF000000 | int.parse(BRIGHT.value.substring(1), radix: 16)),
  ),
);

/// Site-wide rules: the bundled faces, and overrides of the package styling.
///
/// This block is emitted before `jaspr_content`'s, so every override carries a
/// scoping ancestor.
abstract final class IgnisStyles {
  @css
  static List<StyleRule> get styles => [
    ..._faces,
    ..._type,
    ..._chrome,
    ..._callouts,
    ..._brackets,
    ..._lists,
  ];

  /// Markdown makes a list loose once any entry has a second block, and the
  /// package then gives entry paragraphs `1.25em` over the entry's own `0.5em`.
  /// These take a top-level entry's own paragraphs back to `0.25em`. Paragraphs
  /// inside a callout keep their own rules.
  static List<StyleRule> get _lists => [
    css('.docs .content > ul > li, .docs .content > ol > li').styles(
      margin: .symmetric(vertical: 0.25.em),
    ),
    css('.docs .content > ul > li > p, .docs .content > ol > li > p').styles(
      margin: .symmetric(vertical: 0.25.em),
    ),
    css(
      '.docs .content > ul > li > p:first-child, '
      '.docs .content > ol > li > p:first-child',
    ).styles(margin: .only(top: Unit.zero)),
    css(
      '.docs .content > ul > li > p:last-child, '
      '.docs .content > ol > li > p:last-child',
    ).styles(margin: .only(bottom: Unit.zero)),
  ];

  /// The display face, and the root size.
  ///
  /// [ContentTheme.typography] reaches inside `.content` only, so the wordmark
  /// and page title need the display face set here. IM FELL has no bold, hence
  /// 400.
  ///
  /// Garamond runs small, so the root size and the `rem`-sized sidebar are
  /// lifted.
  static List<StyleRule> get _type => [
    css(':root').styles(fontSize: 17.px),
    css('.docs .header .header-title span').styles(
      fontFamily: FontFamily('IM FELL Great Primer'),
      fontSize: 1.375.rem,
      fontWeight: .w400,
      letterSpacing: 0.02.em,
    ),
    css('.docs .content-header h1').styles(
      fontFamily: FontFamily('IM FELL Great Primer'),
      fontWeight: .w400,
      letterSpacing: 0.01.em,
    ),
    css('.docs .sidebar').styles(
      fontSize: 1.rem,
      lineHeight: 1.4.em,
    ),
    css('.docs .sidebar .sidebar-group').styles(
      padding: .only(top: 1.rem, right: 0.75.rem),
    ),
    css('.docs .sidebar .sidebar-group h3').styles(
      margin: .only(top: Unit.zero, bottom: 0.375.rem),
      fontSize: 0.875.rem,
    ),
    css('.docs .sidebar .sidebar-group li a').styles(
      padding: .only(left: 0.75.rem, top: 0.1875.rem, bottom: 0.1875.rem),
    ),
  ];

  /// The highlighter rainbows brackets by depth through private inline styles,
  /// which only `!important` can beat. All five collapse onto the muted tone
  /// `meta.brace` already gets.
  static List<StyleRule> get _brackets => [
    for (final hex in ['#5caeef', '#dfb976', '#c172d9', '#4fb1bc', '#97c26c'])
      css('.content pre code span[style*="$hex"]').styles(
        raw: {'color': 'var(--muted) !important'},
      ),
  ];

  static List<StyleRule> get _faces => [
    _face('EB Garamond', 'eb-garamond', weight: '400 800'),
    _face('EB Garamond', 'eb-garamond-italic', weight: '400 800', style: 'italic'),
    _face('IM FELL Great Primer', 'im-fell-great-primer'),
    _face('IM FELL Great Primer', 'im-fell-great-primer-italic', style: 'italic'),
    _face('iA Writer Mono', 'ia-writer-mono'),
    _face('iA Writer Mono', 'ia-writer-mono-bold', weight: '700'),
    _face('iA Writer Mono', 'ia-writer-mono-italic', style: 'italic'),
  ];

  /// Jaspr's typed `css.fontFace` emits no `format()`, weight, or display, so
  /// the raw form is the only one that can describe these files.
  static StyleRule _face(
    String family,
    String file, {
    String weight = '400',
    String style = 'normal',
  }) {
    return css('@font-face').styles(
      raw: {
        'font-family': '"$family"',
        'src': 'url("/fonts/$file.woff2") format("woff2")',
        'font-weight': weight,
        'font-style': style,
        'font-display': 'swap',
      },
    );
  }

  /// Page chrome: borders, measure, scroll offsets, header controls.
  static List<StyleRule> get _chrome => [
    // 80rem is far past a readable measure on a wide display.
    css('.docs .main-container .content-container').styles(maxWidth: 46.rem),
    // Square corners, so a scene's outermost wireframe is not clipped.
    css('.docs .content pre').styles(radius: .circular(Unit.zero)),
    css('.docs .header-container .header').styles(
      border: .only(
        bottom: BorderSide(width: 1.px, color: IgnisTokens.border),
      ),
    ),
    // Same specificity as the package's rule, emitted later. Theirs is
    // mobile-only, so this also edges the sidebar on desktop.
    css('.docs .main-container .sidebar-container').styles(
      border: .only(
        right: BorderSide(width: 1.px, color: IgnisTokens.border),
      ),
    ),
    // The description belongs to <meta> and link previews, not the page body.
    css('.docs .content-header p').styles(display: .none),
    // The overview's hero header. `order` lifts the mark above the title
    // without touching the markup, and the description returns from the rule
    // above.
    css('.docs .content-header:has(img)', [
      css('&').styles(
        display: .flex,
        margin: .only(bottom: 3.rem),
        flexDirection: .column,
        alignItems: .center,
        textAlign: .center,
      ),
      css('img').styles(
        width: 9.rem,
        height: Unit.auto,
        margin: .zero,
        radius: .circular(Unit.zero),
        raw: {'order': '1'},
      ),
      css('h1').styles(
        margin: .only(top: 1.25.rem),
        fontSize: 4.rem,
        lineHeight: 1.1.em,
        raw: {'order': '2'},
      ),
      css('p').styles(
        display: .block,
        margin: .only(top: 0.75.rem),
        lineHeight: 1.4.em,
        raw: {'order': '3'},
      ),
    ]),
    // Borrows `GitHubButton`'s metrics so the two match.
    css('.docs .header .header-api', [
      css('&').styles(
        display: .flex,
        padding: .symmetric(horizontal: 0.7.rem, vertical: 0.4.rem),
        radius: .circular(8.px),
        alignItems: .center,
        gap: .column(0.5.rem),
        color: ContentColors.text,
        // Set as an identifier; `w700` is the bold face that ships.
        fontFamily: ContentTheme.currentCodeFont,
        fontSize: 0.7.rem,
        fontWeight: .w700,
        textDecoration: .none,
        letterSpacing: 0.02.em,
        lineHeight: 1.2.em,
      ),
      css('&:hover').styles(backgroundColor: IgnisTokens.surface),
      css('svg').styles(width: 1.2.rem, height: 1.2.rem),
    ]),
    // Garamond's middle dot sits low. Set in the mono and nudged onto the cap
    // line beside "API".
    css('.docs .header .header-separator').styles(
      display: .flex,
      alignItems: .center,
      color: IgnisTokens.muted,
      fontFamily: ContentTheme.currentCodeFont,
      fontSize: 1.rem,
      raw: {'user-select': 'none', 'transform': 'translateY(-0.08em)'},
    ),
    css('.docs .sidebar-container').styles(
      raw: {
        'scrollbar-width': 'thin',
        'scrollbar-color': '${BORDER.value} transparent',
      },
    ),
    css('.docs .sidebar-container::-webkit-scrollbar').styles(width: 0.5.rem),
    css('.docs .sidebar-container::-webkit-scrollbar-track').styles(
      backgroundColor: Colors.transparent,
    ),
    css('.docs .sidebar-container::-webkit-scrollbar-thumb').styles(
      radius: .circular(0.25.rem),
      backgroundColor: BORDER,
    ),
    css('.docs .sidebar-container:hover::-webkit-scrollbar-thumb').styles(
      backgroundColor: DIM,
    ),
    css('.docs .sidebar li > div:hover').styles(backgroundColor: IgnisTokens.surface),
    css('.docs .sidebar li > div.active').styles(backgroundColor: IgnisTokens.surface),
    css('.docs .toc a, .related a').styles(
      raw: {
        'text-decoration': 'underline',
        'text-decoration-color': 'transparent',
        'text-underline-offset': '0.2em',
        'transition': 'color 150ms ease, text-decoration-color 150ms ease',
      },
    ),
    css('.docs .toc a:hover, .related a:hover').styles(
      color: IgnisTokens.primaryHi,
      raw: {'text-decoration-color': 'currentColor'},
    ),
    // Clears the 4rem fixed header. In `rem` so the gap does not scale with
    // the heading.
    css(
      '.docs .content :is(h1, h2, h3, h4), .docs .reference',
    ).styles(raw: {'scroll-margin-top': '6rem'}),
  ];

  /// `Callout` hardcodes its colors, and its dark set keys on
  /// `[data-theme="dark"]`, which this site never sets. Scoping under
  /// `.content` outranks both.
  static List<StyleRule> get _callouts => [
    css('.content .callout', [
      css('&').styles(backgroundColor: IgnisTokens.surface),
      for (final variant in _calloutEdges.entries)
        css('&.callout-${variant.key}').styles(
          border: .all(width: 1.px, color: variant.value),
          color: ContentColors.text,
          backgroundColor: IgnisTokens.surface,
        ),
    ]),
  ];

  static Map<String, Color> get _calloutEdges => {
    'info': IgnisTokens.border,
    'warning': ContentColors.primary,
    'error': EMBER,
    'success': IgnisTokens.muted,
  };
}
