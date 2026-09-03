// SPDX-AI-Disclosure: none

import 'package:ignis/src/core.dart';
import 'package:ignis/src/routing/backdrop.dart';

/// Keeps painting, frozen in place.
class FrozenBackdrop extends Backdrop {
  const FrozenBackdrop();

  @override
  Activity get running => .render;

  @override
  Activity get settled => .render;
}
