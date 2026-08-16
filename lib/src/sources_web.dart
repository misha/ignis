/// The `dart:io`-free stand-in for [LocalSources].
///
/// Targeted reloading needs a filesystem to compare against, so on the web
/// this reports nothing ever changed. A scene installed with it reassembles
/// in full, exactly as it would with no source tracking at all. It exists so
/// installing one compiles everywhere.
class LocalSources {
  /// The project directory sources would be resolved against.
  final String root;

  /// Whether source tracking is active. Always false here.
  bool get isRunning => false;

  /// The packages being tracked. Always empty here.
  Iterable<String> get watching => const [];

  LocalSources({
    String? root,
  }) : root = root ?? '';

  /// Does nothing, and reports that source tracking did not start.
  Future<bool> start() async => false;

  /// Always empty, which every caller reads as "rebuild everything".
  Set<String> changed() => const {};

  void stop() {
    // Nothing to do.
  }
}
