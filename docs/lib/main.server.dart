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

import 'components/callouts.dart';
import 'components/coverage.dart';
import 'components/demo.dart';
import 'components/drag_and_drop_demo.dart';
import 'components/status_banner.dart';
import 'theme.dart';

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

  @override
  Component buildBody(Page page, Component child) {
    // Injected here rather than written into every page, so a page cannot
    // quietly forget to admit how finished it is.
    return super.buildBody(page, .fragment([StatusBanner(page: page), child]));
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
      // <Coverage/> reports on every page, so every page must be loaded before
      // the first one renders.
      eagerlyLoadAllPages: true,
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
        // The <Why> and <Lineage> registers.
        Callouts(),
        // Adds syntax highlighting to code blocks.
        CodeBlock(codeTheme: ignisCodeTheme),
        // The per-page status table on the overview.
        Coverage(),
        // Every <Demo name="..."/> slot on the site.
        Demo(),
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
            logo: '/images/ignis-mark.webp',
            items: [
              // Enables switching between light and dark mode.
              ThemeToggle(),
              // Shows github stats.
              GitHubButton(repo: 'misha/ignis'),
            ],
          ),
          sidebar: Sidebar(
            groups: [
              SidebarGroup(
                links: [
                  SidebarLink(text: 'Overview', href: '/'),
                  SidebarLink(text: 'Motivation', href: '/motivation'),
                  SidebarLink(text: 'Your first scene', href: '/start'),
                ],
              ),
              SidebarGroup(
                title: 'Concepts',
                links: [
                  SidebarLink(text: 'Nodes', href: '/concepts/nodes'),
                  SidebarLink(text: 'Building', href: '/concepts/building'),
                  SidebarLink(text: 'Scenes', href: '/concepts/scenes'),
                  SidebarLink(text: 'Signals', href: '/concepts/signals'),
                  SidebarLink(text: 'Time', href: '/concepts/time'),
                  SidebarLink(text: 'Math', href: '/concepts/math'),
                  SidebarLink(text: 'Live reload', href: '/concepts/live-reload'),
                ],
              ),
              SidebarGroup(
                title: 'Systems',
                links: [
                  SidebarLink(text: 'Nodes', href: '/systems/nodes'),
                  SidebarLink(text: 'Layout', href: '/systems/layout'),
                  SidebarLink(text: 'Effects', href: '/systems/effects'),
                  SidebarLink(text: 'Effect controllers', href: '/systems/effect-controllers'),
                  SidebarLink(text: 'Sprites', href: '/systems/sprites'),
                  SidebarLink(text: 'Palettes', href: '/systems/palettes'),
                  SidebarLink(text: 'Collisions', href: '/systems/collisions'),
                  SidebarLink(text: 'Inputs', href: '/systems/inputs'),
                  SidebarLink(text: 'Assets', href: '/systems/assets'),
                  SidebarLink(text: 'Shapes and anchors', href: '/systems/shapes-anchors'),
                  SidebarLink(text: 'Embedding', href: '/systems/embedding'),
                  SidebarLink(text: 'Globals and DI', href: '/systems/globals-di'),
                ],
              ),
              SidebarGroup(
                title: 'Debugging',
                links: [
                  SidebarLink(text: 'Debugging', href: '/debugging'),
                ],
              ),
              SidebarGroup(
                title: 'Internals',
                links: [
                  SidebarLink(text: 'Principles', href: '/internals/principles'),
                  SidebarLink(text: 'Programming model', href: '/internals/programming-model'),
                  SidebarLink(text: 'Tree', href: '/internals/tree'),
                  SidebarLink(text: 'Collisions', href: '/internals/collisions'),
                  SidebarLink(text: 'Layout', href: '/internals/layout'),
                  SidebarLink(text: 'Inputs', href: '/internals/inputs'),
                ],
              ),
            ],
          ),
        ),
      ],
      theme: ignisTheme,
    ),
  );
}
