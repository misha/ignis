// SPDX-AI-Disclosure: none

import 'package:ignis/src/core.dart';
import 'package:ignis/src/routing/backdrop.dart';

/// Keeps updating and rendering throughout, as if nothing were over it.
class LiveBackdrop extends Backdrop {
  const LiveBackdrop();

  @override
  Activity get running => Activity.update | .render;

  @override
  Activity get settled => Activity.update | .render;
}
