/// The entrypoint for the **server** environment.
///
/// The [main] method will only be executed on the server during pre-rendering.
/// To run code on the client, check the `main.client.dart` file.
library;

// Server-specific Jaspr import.
import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';

import 'package:jaspr_content/components/callout.dart';
import 'package:jaspr_content/components/code_block.dart';
import 'package:jaspr_content/components/github_button.dart';
import 'package:jaspr_content/components/header.dart';
import 'package:jaspr_content/components/image.dart';
import 'package:jaspr_content/components/sidebar.dart';
import 'package:jaspr_content/components/theme_toggle.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:jaspr_content/theme.dart';

import 'components/drag_and_drop_demo.dart';

// This file is generated automatically by Jaspr, do not remove or edit.
import 'main.server.options.dart';

/// [DocsLayout], plus the Flutter loader script every embedded scene needs.
///
/// It defines the `_flutter` global that `jaspr_flutter_embed` boots the engine
/// through. The script is 13 KB and only defines the loader; nothing downloads
/// the engine until a page actually adds a view.
class _IgnisLayout extends DocsLayout {
  // ignore: avoid_types_as_parameter_names, matches DocsLayout's own names.
  const _IgnisLayout({super.header, super.sidebar});

  @override
  Iterable<Component> buildHead(Page page) sync* {
    yield* super.buildHead(page);
    // Relative on purpose: it resolves against the document's <base href>.
    yield script(src: 'flutter_bootstrap.js', async: true);
  }
}

void main() {
  // Initializes the server environment with the generated default options.
  Jaspr.initializeApp(
    options: defaultServerOptions,
  );

  // Starts the app.
  //
  // [ContentApp] spins up the content rendering pipeline from jaspr_content to render
  // your markdown files in the content/ directory to a beautiful documentation site.
  runApp(
    ContentApp(
      // Enables mustache templating inside the markdown files.
      templateEngine: MustacheTemplateEngine(),
      parsers: [
        MarkdownParser(),
      ],
      extensions: [
        // Adds heading anchors to each heading.
        HeadingAnchorsExtension(),
        // Generates a table of contents for each page.
        TableOfContentsExtension(),
      ],
      components: [
        // The <Info> block and other callouts.
        Callout(),
        // Adds syntax highlighting to code blocks.
        CodeBlock(),
        // Embeds the drag-and-drop scene as <DragAndDropDemo/> in markdown.
        CustomComponent(
          pattern: 'DragAndDropDemo',
          builder: (_, _, _) => DragAndDropDemo(),
        ),
        // Adds zooming and caption support to images.
        Image(zoom: true),
      ],
      layouts: [
        // Out-of-the-box layout for documentation sites.
        _IgnisLayout(
          header: Header(
            title: 'Ignis',
            logo: '/images/logo.svg',
            items: [
              // Enables switching between light and dark mode.
              ThemeToggle(),
              // Shows github stats.
              GitHubButton(repo: 'misha/ignis'),
            ],
          ),
          sidebar: Sidebar(
            groups: [
              // Adds navigation links to the sidebar.
              SidebarGroup(
                links: [
                  SidebarLink(text: 'Overview', href: '/'),
                ],
              ),
              SidebarGroup(
                title: 'Guides',
                links: [
                  SidebarLink(text: 'Inputs', href: '/inputs'),
                ],
              ),
            ],
          ),
        ),
      ],
      theme: ContentTheme(
        // Customizes the default theme colors.
        primary: ThemeColor(ThemeColors.blue.$500, dark: ThemeColors.blue.$300),
        background: ThemeColor(ThemeColors.slate.$50, dark: ThemeColors.zinc.$950),
        colors: [
          ContentColors.quoteBorders.apply(ThemeColors.blue.$400),
        ],
      ),
    ),
  );
}
