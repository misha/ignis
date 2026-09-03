// SPDX-AI-Disclosure: none

import 'package:ignis/src/core.dart';
import 'package:ignis/src/routing/backdrop.dart';

/// Paints during navigation, and then not at all.
///
/// Intended for a push that fills the region with opaque content, where
/// painting beneath it is wasted work.
class HiddenBackdrop extends Backdrop {
  const HiddenBackdrop();

  @override
  Activity get running => .render;

  @override
  Activity get settled => .none;
}
