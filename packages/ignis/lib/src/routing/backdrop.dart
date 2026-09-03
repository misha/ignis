// SPDX-AI-Disclosure: none

import 'package:ignis/src/core.dart';
import 'package:ignis/src/routing/backdrops/frozen_backdrop.dart';
import 'package:ignis/src/routing/backdrops/hidden_backdrop.dart';
import 'package:ignis/src/routing/backdrops/live_backdrop.dart';
import 'package:ignis/src/routing/nodes/route_node.dart';

/// Describes how a route treats the route it is pushed over.
abstract class Backdrop {
  // #region API

  const Backdrop();

  /// What the covered route takes part in while the push runs.
  Activity get running;

  /// What the covered route takes part in once the push settles.
  Activity get settled;

  /// Poses the [covered] route at [progress] of the push over it.
  ///
  /// Runs once when the push commits and once per tick after the clock moves.
  void apply(double progress, RouteNode covered) {
    // Nothing to do.
  }

  // #endregion

  // #region Shorthand

  const factory Backdrop.frozen() = FrozenBackdrop;
  const factory Backdrop.hidden() = HiddenBackdrop;
  const factory Backdrop.live() = LiveBackdrop;

  // #endregion
}
