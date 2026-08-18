import 'package:jaspr_content/jaspr_content.dart';

/// Where the title's entry points.
///
/// No element carries this id. A fragment of `top` sends the browser to the
/// start of the document, which is where the layout puts the title.
const _TOP = 'top';

/// Puts a page's own title at the head of its table of contents.
///
/// The layout renders the title as the `<h1>` of `.content-header`, outside the
/// content that [TableOfContentsExtension] walks. Without this, naming a page in
/// `On this page` means repeating its title as an `##` directly underneath it.
///
/// Runs after [TableOfContentsExtension], since it rewrites what that stores.
class TitleEntryExtension implements PageExtension {
  const TitleEntryExtension();

  @override
  Future<List<Node>> apply(Page page, List<Node> nodes) async {
    final title = page.data.page['title'];
    if (title is! String) return nodes;

    if (page.data['toc'] case final TableOfContents contents) {
      page.apply(
        data: {
          'toc': TableOfContents([
            TocEntry(title, _TOP, []),
            ...contents.entries,
          ]),
        },
      );
    }

    return nodes;
  }
}
