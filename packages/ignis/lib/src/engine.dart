// SPDX-AI-Disclosure: none

/// A collection of related algorithms.
///
/// Engines live outside the tree and do not operate on nodes or signals.
/// The primary purpose of this class is to act as a marker for this commitment,
/// as well as provide an entrypoint for tests and benchmarks.
abstract class Engine {
  const Engine();
}
