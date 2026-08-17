import 'dart:io';

/// Where the repository serves the file a region was cut from.
const _BLOB = 'https://github.com/misha/ignis/blob/main/docs';

/// Where demo sources live, relative to this package and to the repository.
const _DEMOS = 'lib/widgets/demos';

/// The marker a region opens with, before its name.
const _OPEN = '// #region';

/// The marker a region closes with.
const _CLOSE = '// #endregion';

/// A run of lines cut out of a demo's source.
///
/// The page shows [code] and links to [url], so what a reader reads is the
/// source that ran, down to the line numbers.
class DemoSource {
  /// The lines between the region's markers.
  final String code;

  /// Those same lines, addressed on GitHub.
  final String url;

  const DemoSource({
    required this.code,
    required this.url,
  });

  /// Cuts the region named [region] out of [file].
  ///
  /// ```dart
  /// // #region sprite-animation
  /// class _BonfireNode extends Node { ... }
  /// // #endregion
  /// ```
  ///
  /// Throws if either marker is missing, so a page that names a region which
  /// has since been renamed fails the build rather than shipping empty.
  factory DemoSource.cut(String file, String region) {
    final path = '$_DEMOS/$file';
    final lines = File(path).readAsLinesSync();

    final opened = lines.indexWhere((line) {
      return line.trim() == '$_OPEN $region';
    });

    if (opened < 0) {
      throw StateError('No "$_OPEN $region" in $path.');
    }

    final closed = lines.indexWhere((line) {
      return line.trim() == _CLOSE;
    }, opened);

    if (closed < 0) {
      throw StateError('No "$_CLOSE" after "$_OPEN $region" in $path.');
    }

    return DemoSource(
      code: _dedent(lines.sublist(opened + 1, closed)),
      url: '$_BLOB/$path#L${opened + 2}-L$closed',
    );
  }

  /// Joins [lines], shifted left by the indentation they all share.
  ///
  /// A region cut from inside a method arrives indented by however deep it sat.
  /// The page shows it against its own left edge instead.
  static String _dedent(List<String> lines) {
    var indent = _MAX_INDENT;

    for (final line in lines) {
      final trimmed = line.trimLeft();
      if (trimmed.isEmpty) continue;
      final depth = line.length - trimmed.length;
      if (depth < indent) indent = depth;
    }

    final shifted = [
      for (final line in lines) //
        if (line.length < indent) //
          line
        else
          line.substring(indent),
    ];

    return shifted.join('\n');
  }
}

/// Deeper than any region is indented, as a starting point for the minimum.
const _MAX_INDENT = 1 << 20;
