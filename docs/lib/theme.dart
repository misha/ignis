import 'package:jaspr/dom.dart';
import 'package:jaspr_content/theme.dart';
import 'package:syntax_highlight_lite/syntax_highlight_lite.dart' as hl;

/// The ember ramp, sampled from the painted pixels of `ignis.png`.
///
/// The artwork is the only fixed brand input and it carries no second hue, so
/// every color on the site is either this ramp or a neutral derived from it.
abstract final class Ember {
  static const deep = Color('#780E04');
  static const core = Color('#A32C0D');
  static const burnt = Color('#B65A18');
  static const flame = Color('#C36E21');
  static const amber = Color('#C78F30');
  static const gold = Color('#C99F4F');
  static const pale = Color('#CDC07B');
}

/// Roles the ramp is put to.
///
/// The site is dark, and only dark. A single value per role is the whole of it:
/// nothing here answers to `data-theme`, and nothing needs a second variant
/// checked for contrast against a ground the site never shows.
abstract final class IgnisColors {
  static final surface = ColorToken('surface', Color('#1B1815'));
  static final border = ColorToken('border', Color('#2E2823'));
  static final muted = ColorToken('muted', Color('#9A9186'));
  static final primaryHi = ColorToken('primary-hi', Ember.pale);

  /// Reserved for the mark. Never body text: it fails contrast on this ground.
  static final brand = ColorToken('brand', Ember.core);

  static const _background = ThemeColor(Color('#12100E'));
  static const _text = ThemeColor(Color('#EDE7DD'));
  static const _headings = ThemeColor(Color('#F5F0E8'));
  static const _primary = ThemeColor(Ember.amber);

  /// Every token the site defines.
  static List<ColorToken> get all => [
    surface,
    border,
    muted,
    primaryHi,
    brand,
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
    ContentColors.code.apply(const ThemeColor(Ember.pale)),
    ContentColors.kbd.apply(_headings),
    ContentColors.preBg.apply(const ThemeColor(Color('#1B1815'))),
    ContentColors.preCode.apply(const ThemeColor(Color('#EDE7DD'))),
  ];
}

/// The site theme.
ContentTheme get ignisTheme => ContentTheme(
  primary: IgnisColors._primary,
  background: IgnisColors._background,
  text: IgnisColors._text,
  colors: IgnisColors.all,
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

/// Dart highlighting, drawn from the ramp.
///
/// Monochrome by necessity - the artwork has one hue - so the scopes separate
/// by lightness rather than by color.
final ignisCodeTheme = hl.HighlighterTheme.fromConfiguration(
  '''
{"settings":[
  {"settings":{"foreground":"#EDE7DD"}},
  {"scope":["comment","punctuation.definition.comment"],"settings":{"foreground":"#7A6F62","fontStyle":"italic"}},
  {"scope":["keyword","storage","storage.type","keyword.control","modifier"],"settings":{"foreground":"#C36E21"}},
  {"scope":["entity.name.type","entity.name.class","support.class","support.type"],"settings":{"foreground":"${Ember.pale.value}"}},
  {"scope":["string","string.quoted","constant.character"],"settings":{"foreground":"#B65A18"}},
  {"scope":["constant.numeric","constant.language"],"settings":{"foreground":"#C99F4F"}},
  {"scope":["entity.name.function","support.function","meta.function-call"],"settings":{"foreground":"#F0E4C4"}},
  {"scope":["variable","variable.parameter","meta.definition.variable"],"settings":{"foreground":"#EDE7DD"}},
  {"scope":["keyword.operator","punctuation","meta.brace"],"settings":{"foreground":"#9A9186"}},
  {"scope":["meta.declaration.annotation","storage.type.annotation"],"settings":{"foreground":"#C78F30"}}
]}''',
  hl.TextStyle(foreground: hl.Color(0xFFEDE7DD)),
);

/// Site-wide rules: the bundled faces, and the package styling we have to beat.
///
/// Our `@css` block is emitted before `jaspr_content`'s, so every override here
/// carries a scoping ancestor rather than relying on source order.
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

  /// A catalog page is a list, and the package spaces lists for prose.
  ///
  /// Markdown calls a list loose the moment any entry carries a second block -
  /// a callout, a diagram - and wraps every entry's content in a paragraph. The
  /// package then gives those paragraphs `1.25em` top and bottom, over the
  /// `0.5em` it gives the entry itself, and the entries drift apart until the
  /// list reads as separate paragraphs that happen to have bullets.
  ///
  /// These take an entry's own paragraphs back to the line. Paragraphs deeper
  /// in - inside a callout - are left to the rules that own them.
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

  /// The display face, and the size everything else is measured against.
  ///
  /// [ContentTheme.typography] reaches inside `.content` only, so the wordmark
  /// and the page title - the largest type on any page - were being set in the
  /// prose face. IM FELL carries no bold, so both ask for 400 rather than let
  /// the browser synthesize one.
  ///
  /// Garamond runs small for its point size. The root size lifts the whole
  /// site to suit it, and the sidebar, which the package sets in `rem`, is
  /// brought up further and tightened to match.
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

  /// The highlighter colors brackets by nesting depth from a hardcoded
  /// five-hue rainbow (`_bracketStyles`, private and top-level, so neither
  /// themeable nor overridable in Dart). It writes them as inline styles, which
  /// only `!important` can beat. Punctuation should be quiet, so all five
  /// collapse onto the muted tone the theme already gives `meta.brace`.
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

  /// The three hairlines `jaspr_content` hardcodes to black at 5%, which is
  /// invisible on a dark ground, and the measure it lets prose run to.
  static List<StyleRule> get _chrome => [
    // The package allows 80rem, which is a paragraph a line long on a wide
    // display. The column holds a comfortable measure instead, and the layout
    // centers what it no longer uses.
    css('.docs .main-container .content-container').styles(maxWidth: 46.rem),
    css('.docs .header-container .header').styles(
      border: .only(
        bottom: BorderSide(width: 1.px, color: IgnisColors.border),
      ),
    ),
    // Matches the package's own `.docs .main-container .sidebar-container`
    // specificity; ours is emitted later, so the tie falls our way. Theirs is
    // mobile-only, so this also gives the sidebar an edge on desktop.
    css('.docs .main-container .sidebar-container').styles(
      border: .only(
        right: BorderSide(width: 1.px, color: IgnisColors.border),
      ),
    ),
    // A page's `description` stays in frontmatter, where it is the page's
    // `<meta name="description">` and its link preview, but it is not also
    // printed under the title. The layout renders it as plain text, so it can
    // carry no code and name no class, and the page's opening line says the
    // same thing in a register that can.
    css('.docs .content-header p').styles(display: .none),
    // A page carrying an `image` is the hero, and only the overview does. The
    // layout emits the header as title, description, mark, so `order` puts the
    // painting on top without the markup moving, and the description comes back
    // from the rule above to serve as the centered opening line.
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
    // Sits beside `GitHubButton` and borrows its metrics, so the two read as
    // one pair rather than a link next to a button.
    css('.docs .header .header-api', [
      css('&').styles(
        display: .flex,
        padding: .symmetric(horizontal: 0.7.rem, vertical: 0.4.rem),
        radius: .circular(8.px),
        alignItems: .center,
        gap: .column(0.5.rem),
        color: ContentColors.text,
        // The acronym reads as an identifier, not as prose, and `w700` lands on
        // the bold face that ships rather than a synthesized one.
        fontFamily: ContentTheme.currentCodeFont,
        fontSize: 0.7.rem,
        fontWeight: .w700,
        textDecoration: .none,
        letterSpacing: 0.02.em,
        lineHeight: 1.2.em,
      ),
      css('&:hover').styles(backgroundColor: IgnisColors.surface),
      css('svg').styles(width: 1.2.rem, height: 1.2.rem),
    ]),
    // Garamond sets its middle dot small and low, which reads as a full stop
    // beside capitals. The mono centers it, and the size lifts it clear.
    //
    // Centering agrees on boxes, not on ink. `API` is capitals, so it rides
    // above its box center, and a middle dot sits below its own. The nudge is
    // the sum of the two, which lands the dot on the cap line.
    css('.docs .header .header-separator').styles(
      display: .flex,
      alignItems: .center,
      color: IgnisColors.muted,
      fontFamily: ContentTheme.currentCodeFont,
      fontSize: 1.rem,
      raw: {'user-select': 'none', 'transform': 'translateY(-0.08em)'},
    ),
    css('.docs .sidebar-container').styles(
      raw: {
        'scrollbar-width': 'thin',
        'scrollbar-color': '#2E2823 transparent',
      },
    ),
    css('.docs .sidebar-container::-webkit-scrollbar').styles(width: 0.5.rem),
    css('.docs .sidebar-container::-webkit-scrollbar-track').styles(
      backgroundColor: Colors.transparent,
    ),
    css('.docs .sidebar-container::-webkit-scrollbar-thumb').styles(
      radius: .circular(0.25.rem),
      backgroundColor: const Color('#2E2823'),
    ),
    css('.docs .sidebar-container:hover::-webkit-scrollbar-thumb').styles(
      backgroundColor: const Color('#6B6156'),
    ),
    css('.docs .sidebar li > div:hover').styles(backgroundColor: IgnisColors.surface),
    css('.docs .sidebar li > div.active').styles(backgroundColor: IgnisColors.surface),
    css('.docs .toc a, .related a').styles(
      raw: {
        'text-decoration': 'underline',
        'text-decoration-color': 'transparent',
        'text-underline-offset': '0.2em',
        'transition': 'color 150ms ease, text-decoration-color 150ms ease',
      },
    ),
    css('.docs .toc a:hover, .related a:hover').styles(
      color: IgnisColors.primaryHi,
      raw: {'text-decoration-color': 'currentColor'},
    ),
    // The header is fixed and frosted, and the package puts its height at 4rem
    // where it offsets the sidebar. Landing an anchor at the target's own top
    // parks it under that glass, so every target clears the header and keeps a
    // gap besides. In `rem`, since `em` here would scale the gap by whatever
    // the heading it lands on happens to be set in.
    css(
      '.docs .content :is(h1, h2, h3, h4), .docs .reference',
    ).styles(raw: {'scroll-margin-top': '6rem'}),
  ];

  /// `Callout` reaches for no theme token at all - every color in it is a
  /// hardcoded sky/amber/red/green, at `.callout.callout-info` and the like.
  ///
  /// The `.content` these sit under carries them past that. The package's own
  /// dark set is written as `[data-theme="dark"] .callout`, and nothing on this
  /// site sets that attribute, so it never applies.
  static List<StyleRule> get _callouts => [
    css('.content .callout', [
      css('&').styles(backgroundColor: IgnisColors.surface),
      for (final variant in _calloutEdges.entries)
        css('&.callout-${variant.key}').styles(
          border: .all(width: 1.px, color: variant.value),
          color: ContentColors.text,
          backgroundColor: IgnisColors.surface,
        ),
    ]),
  ];

  /// Semantic edges. The palette has one hue, so severity reads through
  /// lightness: quiet for info, the accent for warning, the core ember for
  /// error.
  static Map<String, Color> get _calloutEdges => {
    'info': IgnisColors.border,
    'warning': ContentColors.primary,
    'error': Ember.core,
    'success': IgnisColors.muted,
  };
}
