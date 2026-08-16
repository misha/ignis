import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Tracks which of the project's Dart files have changed, so a reassembly can
/// rebuild only the nodes written in them.
///
/// Local, as in the app and the project source must share a filesystem: the
/// machine hosting the project, and nowhere else.
///
/// Install it over `Ignis.sources`, then [start] it:
///
/// ```dart
/// final sources = LocalSources();
/// Ignis.sources = sources;
/// await sources.start();
/// ```
///
/// Outside [kDebugMode] this is inert. [start] does nothing and [changed] is
/// always empty, making it safe to install unconditionally.
///
/// Tracking is by modification time rather than by watching, so there is no
/// stream to miss and no race with the reload that follows a save: [changed]
/// answers from the filesystem at the moment it is asked.
class LocalSources {
  /// The project directory holding `.dart_tool/package_config.json`.
  final String root;

  final _packages = <_Package>[];
  final _stamps = <String, DateTime>{};
  var _running = false;

  /// Whether source tracking is active.
  bool get isRunning => _running;

  /// The packages being tracked, which are the ones whose source lives in the
  /// project tree rather than the pub cache.
  ///
  /// This is the answer to why an edit did or did not reload anything.
  Iterable<String> get watching => _packages.map((package) => package.name);

  /// Creates a tracker rooted at [root], defaulting to the working directory
  /// of the running process.
  LocalSources({
    String? root,
  }) : root = root ?? Directory.current.path;

  /// Reads the package config and takes the first snapshot.
  ///
  /// Returns whether tracking started, which it does not outside debug mode
  /// or without a package config to read.
  Future<bool> start() async {
    if (!kDebugMode) return false;
    final config = File(p.join(root, '.dart_tool', 'package_config.json'));
    if (!config.existsSync()) return false;

    final parsed = jsonDecode(await config.readAsString());
    if (parsed is! Map<String, dynamic>) return false;
    final packages = parsed['packages'];
    if (packages is! List) return false;
    _packages.clear();

    for (final package in packages) {
      if (package is! Map<String, dynamic>) continue;
      final rootUri = package['rootUri'];
      final packageUri = package['packageUri'];
      final name = package['name'];
      if (rootUri is! String || packageUri is! String || name is! String) {
        continue;
      }

      // A hosted or SDK package roots at an absolute URI, and is not source
      // anyone is editing. Path dependencies and the project itself are
      // relative to `.dart_tool`, and are.
      if (Uri.parse(rootUri).hasScheme) continue;
      final lib = p.normalize(p.join(root, '.dart_tool', rootUri, packageUri));
      if (!Directory(lib).existsSync()) continue;
      _packages.add(_Package(name, lib));
    }

    if (_packages.isEmpty) return false;
    _running = true;

    // Prime, so the first real call reports edits rather than everything.
    changed();
    return true;
  }

  /// The `package:` URIs whose files have changed since the last call.
  ///
  /// Empty when nothing changed, which callers read as "rebuild everything" -
  /// the safe answer, since a reload that reports nothing is more likely to
  /// have out-run this than to have changed nothing.
  Set<String> changed() {
    if (!_running) return const {};
    final changed = <String>{};
    final seen = <String>{};

    for (final package in _packages) {
      for (final file in package.sources()) {
        final uri = package.uriOf(file);
        seen.add(uri);
        final stamp = file.statSync().modified;
        if (_stamps[uri] == stamp) continue;
        _stamps[uri] = stamp;
        changed.add(uri);
      }
    }

    // A deleted file is a change too, and it must leave the snapshot or it
    // reports forever.
    _stamps.removeWhere((uri, _) {
      if (seen.contains(uri)) return false;
      changed.add(uri);
      return true;
    });

    return changed;
  }

  void stop() => _running = false;
}

/// One tracked package, and the `lib/` directory its `package:` URIs address.
final class _Package {
  final String name;
  final String lib;

  const _Package(this.name, this.lib);

  Iterable<File> sources() {
    return Directory(lib)
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
  }

  String uriOf(File file) => 'package:$name/${p.relative(file.path, from: lib)}';
}
