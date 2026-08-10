import 'dart:math';

/// Global [Random] instance used as a default parameter throughout Ignis.
///
/// Mutable to allow for seeding or replacement during (single-threaded) tests.
Random rng = .new();
