import 'dart:async';

import 'package:ignis/ignis.dart';

import 'support/test_bundle.dart';

/// Serves `test/assets/` off disk for the whole suite.
///
/// The package declares no Flutter assets, so `rootBundle` has nothing to hand
/// out. A test that cares about the manifest installs its own [TestBundle].
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  Ignis.bundle = TestBundle();
  await testMain();
}
