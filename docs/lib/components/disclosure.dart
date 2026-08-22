import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:jaspr_content/theme.dart';

/// `<Disclosure/>`: how much of the repository a model wrote.
///
/// Reads `content/_data/disclosure.json`, which `tool/disclosure.dart`
/// generates by resolving every file's own `SPDX-AI-Disclosure` tag against the
/// default in `AI_DISCLOSURE.md`. Groups are rows in this table and nothing
/// else; disclosure itself is always per file.
///
/// `<Disclosure excluded/>` renders the second table, of files that have no
/// provenance to state. It is a separate tag so the page owns the heading above
/// it, and so the table of contents can see that heading.
class Disclosure extends CustomComponentBase {
  Disclosure();

  @override
  final Pattern pattern = 'Disclosure';

  @override
  Component apply(String name, Map<String, String> attributes, Component? child) {
    if (attributes.containsKey('excluded')) return _ExcludedTable();

    return _GroupTable();
  }

  @css
  static List<StyleRule> get styles => [
    css('.disclosure', [
      css('&').styles(width: 100.percent),
      css('& td').styles(
        padding: .symmetric(vertical: 0.375.rem, horizontal: 0.5.rem),
        textAlign: .left,
      ),
      css('& th').styles(
        padding: .symmetric(vertical: 0.375.rem, horizontal: 0.5.rem),
        textAlign: .left,
      ),
      css('.disclosure-level').styles(
        color: ContentColors.text,
        fontSize: 0.8125.rem,
      ),
      css('.disclosure-count').styles(
        width: 4.rem,
        color: ContentColors.text,
        textAlign: .right,
        fontSize: 0.8125.rem,
      ),
    ]),
  ];
}

class _GroupTable extends StatelessComponent {
  @override
  Component build(BuildContext context) {
    final data = context.page.data['disclosure'] as Map<String, Object?>?;

    if (data == null) {
      return p([.text('Run `dart run tool/disclosure.dart` to generate this table.')]);
    }

    final groups = (data['groups'] as List).cast<Map<String, Object?>>();
    final files = data['files'] as int;
    final tagged = data['tagged'] as int;

    return .fragment([
      p([.text(_summary(files, tagged, data['default'] as String))]),
      table(classes: 'disclosure', [
        thead([
          tr([
            th([.text('Group')]),
            th(classes: 'disclosure-count', [.text('Files')]),
            th([.text('Disclosure')]),
          ]),
        ]),
        tbody([
          for (final group in groups)
            tr([
              td([.text(group['label'] as String)]),
              td(classes: 'disclosure-count', [.text('${group['files']}')]),
              td(classes: 'disclosure-level', [
                .text(_levels(group['levels'] as Map<String, Object?>)),
              ]),
            ]),
        ]),
      ]),
    ]);
  }

  /// Reads the whole repository in one sentence, however few tags exist.
  String _summary(int files, int tagged, String fallback) {
    if (tagged == 0) {
      return '$files files, none of which departs from the repository default of $fallback.';
    }

    return '$files files. $tagged state their own disclosure; the rest inherit $fallback.';
  }

  /// The single value a uniform group resolves to, or what it is made of.
  String _levels(Map<String, Object?> levels) {
    if (levels.length == 1) return levels.keys.single;

    return [for (final level in levels.entries) '${level.value} ${level.key}'].join(' · ');
  }
}

class _ExcludedTable extends StatelessComponent {
  @override
  Component build(BuildContext context) {
    final data = context.page.data['disclosure'] as Map<String, Object?>?;

    if (data == null) {
      return p([.text('Run `dart run tool/disclosure.dart` to generate this table.')]);
    }

    final excluded = (data['excluded'] as List).cast<Map<String, Object?>>();

    return table(classes: 'disclosure', [
      thead([
        tr([
          th([.text('Group')]),
          th(classes: 'disclosure-count', [.text('Files')]),
          th([.text('Reason')]),
        ]),
      ]),
      tbody([
        for (final entry in excluded)
          tr([
            td([.text(entry['label'] as String)]),
            td(classes: 'disclosure-count', [.text('${entry['files']}')]),
            td(classes: 'disclosure-level', [.text(entry['reason'] as String)]),
          ]),
      ]),
    ]);
  }
}
