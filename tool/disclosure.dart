// SPDX-AI-Disclosure: ai-generated

// Generates the AI disclosure report the documentation site renders.
//
//   dart run tool/disclosure.dart
//
// The site's `build` and `serve` scripts run this first, so the report is built
// from the tree it describes and ships inside the artifact. It is not committed
// and there is nothing to keep in sync by hand.
//
// Disclosure is per file: a file's own SPDX-AI-Disclosure tag, or the
// disclosure-default from AI_DISCLOSURE.md when it carries none. Groups come
// from tool/disclosure.yaml and exist only to give the report its rows.

import 'dart:convert';
import 'dart:io';

import 'package:glob/glob.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

const _DISCLOSURE = 'AI_DISCLOSURE.md';
const _CONFIG = 'tool/disclosure.yaml';
const _REPORT = 'docs/content/_data/disclosure.json';

/// The vocabulary, in the order the report lists it.
const _VALUES = ['none', 'ai-assisted', 'ai-generated', 'autonomous'];

/// How far into a file a tag may sit.
///
/// Far enough to clear a shebang, a license header, a library doc comment or a
/// page's frontmatter, and short enough that the walk stays cheap.
const _SCAN_LINES = 30;

final _TAG = RegExp(r'SPDX-AI-Disclosure:\s*([\w-]+)', caseSensitive: false);

void main(List<String> arguments) {
  if (arguments.isNotEmpty) {
    _fail(['usage: dart run tool/disclosure.dart']);
  }

  if (!File(_DISCLOSURE).existsSync()) {
    _fail(['$_DISCLOSURE is missing. Run this from the repository root.']);
  }

  final report = _generate();

  File(_REPORT).writeAsStringSync('${JsonEncoder.withIndent('  ').convert(report)}\n');
  print('${report['files']} files, ${report['tagged']} tagged -> $_REPORT');
}

/// Resolves the cascade over every tracked file and buckets the result.
Map<String, Object?> _generate() {
  final frontmatter = _frontmatter(File(_DISCLOSURE));
  final declared = frontmatter['disclosure-default'];
  final fallback = '$declared'.toLowerCase();

  if (!_VALUES.contains(fallback)) {
    _fail([
      'disclosure-default in $_DISCLOSURE is ${declared ?? 'missing'}.',
      'It must be one of ${_VALUES.join(', ')}.',
    ]);
  }

  final config = loadYaml(File(_CONFIG).readAsStringSync()) as YamlMap;
  final groups = _entries(config, 'groups');
  final excluded = _entries(config, 'excluded');
  final tracked = _tracked();
  final counts = {
    for (final group in groups) //
      group.label: <String, int>{},
  };

  final sizes = {
    for (final entry in [...groups, ...excluded]) //
      entry.label: 0,
  };

  final unclaimed = <String>[];
  final contested = <String, List<String>>{};
  final invalid = <String, String>{};

  var tagged = 0;

  for (final file in tracked) {
    // Excluded first, so a group may claim a directory whole and let the
    // generated files inside it fall back out.
    if (excluded.where((entry) => entry.claims(file)).firstOrNull case final entry?) {
      sizes[entry.label] = sizes[entry.label]! + 1;
      continue;
    }

    final claims = [
      for (final group in groups)
        if (group.claims(file)) group,
    ];

    if (claims.isEmpty) {
      unclaimed.add(file);
      continue;
    }

    if (claims.length > 1) {
      contested[file] = [for (final claim in claims) claim.label];
      continue;
    }

    final tag = _tag(File(file));

    if (tag != null && !_VALUES.contains(tag)) {
      invalid[file] = tag;
      continue;
    }

    if (tag != null) tagged++;

    final label = claims.single.label;
    final level = tag ?? fallback;

    counts[label]![level] = (counts[label]![level] ?? 0) + 1;
    sizes[label] = sizes[label]! + 1;
  }

  if (unclaimed.isNotEmpty) {
    _fail([
      'These paths match no entry in $_CONFIG:',
      ...unclaimed.map((file) => '  $file'),
    ]);
  }

  if (contested.isNotEmpty) {
    _fail([
      'These paths are claimed by more than one group:',
      ...contested.entries.map((entry) => '  ${entry.key} -> ${entry.value.join(', ')}'),
    ]);
  }

  if (invalid.isNotEmpty) {
    _fail([
      'These files carry a disclosure outside the vocabulary:',
      ...invalid.entries.map((entry) => '  ${entry.key} -> ${entry.value}'),
      'It must be one of ${_VALUES.join(', ')}.',
    ]);
  }

  final empty = [
    for (final entry in [...groups, ...excluded])
      if (sizes[entry.label] == 0) entry.label,
  ];

  if (empty.isNotEmpty) {
    _fail([
      'These entries in $_CONFIG claim no files:',
      ...empty.map((label) => '  $label'),
    ]);
  }

  final totals = <String, int>{};

  for (final group in counts.values) {
    for (final level in group.entries) {
      totals[level.key] = (totals[level.key] ?? 0) + level.value;
    }
  }

  return {
    'default': fallback,
    'models': _strings(frontmatter['models-used']),
    'providers': _strings(frontmatter['providers']),
    'updated': '${frontmatter['last-updated']}',
    'files': totals.values.fold<int>(0, (sum, count) => sum + count),
    'tagged': tagged,
    'levels': _ordered(totals),
    'groups': [
      for (final group in groups)
        {
          'label': group.label,
          'files': sizes[group.label],
          'levels': _ordered(counts[group.label]!),
        },
    ],
    'excluded': [
      for (final entry in excluded)
        {
          'label': entry.label,
          'files': sizes[entry.label],
          'reason': entry.reason,
        },
    ],
  };
}

/// One row of the report, and the paths it answers for.
class _Entry {
  _Entry(this.label, this.reason, List<String> patterns)
    : _globs = [
        for (final pattern in patterns) //
          Glob(pattern, context: path.posix),
      ];

  final String label;
  final String? reason;

  final List<Glob> _globs;

  bool claims(String file) {
    for (final glob in _globs) {
      if (glob.matches(file)) return true;
    }

    return false;
  }
}

List<_Entry> _entries(YamlMap config, String key) {
  final entries = config[key];

  if (entries is! YamlList) {
    _fail(['$_CONFIG has no `$key:` list.']);
  }

  return [
    for (final entry in entries)
      _Entry(
        '${entry['label']}',
        entry['reason'] as String?,
        [for (final pattern in entry['paths'] as YamlList) '$pattern'],
      ),
  ];
}

/// Every file in the working tree that git does not ignore.
///
/// Untracked files count and deleted ones do not, so a change is accounted for
/// before it is committed rather than the run after.
List<String> _tracked() {
  final result = Process.runSync('git', [
    'ls-files',
    '--cached',
    '--others',
    '--exclude-standard',
    '-z',
  ]);

  if (result.exitCode != 0) {
    _fail(['git ls-files failed: ${result.stderr}']);
  }

  return [
    for (final file in '${result.stdout}'.split('\x00'))
      if (file.isNotEmpty && File(file).existsSync()) file,
  ];
}

Map<String, Object?> _frontmatter(File file) {
  final lines = file.readAsLinesSync();
  final end = lines.isNotEmpty && lines.first.trim() == '---' ? lines.indexOf('---', 1) : -1;

  if (end < 0) {
    _fail(['${file.path} opens with no `---` frontmatter block.']);
  }

  final parsed = loadYaml(lines.sublist(1, end).join('\n')) as YamlMap;

  return {
    for (final entry in parsed.entries) //
      '${entry.key}': entry.value,
  };
}

/// The file's own disclosure, when it declares one.
String? _tag(File file) {
  final List<String> lines;

  try {
    lines = file.readAsLinesSync();
  } on FileSystemException {
    // Binary content that slipped past the excluded entries. Reporting it as
    // untagged beats failing the build over an encoding.
    return null;
  }

  for (final line in lines.take(_SCAN_LINES)) {
    if (_TAG.firstMatch(line) case final match?) return match[1]!.toLowerCase();
  }

  return null;
}

List<String> _strings(Object? value) {
  if (value is! YamlList) return [];

  return [for (final entry in value) '$entry'];
}

/// The vocabulary's order, and only the levels that occur.
Map<String, int> _ordered(Map<String, int> counts) {
  return {
    for (final level in _VALUES) level: ?counts[level],
  };
}

Never _fail(List<String> lines) {
  lines.forEach(stderr.writeln);
  exit(1);
}
