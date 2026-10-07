// SPDX-AI-Disclosure: none

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:ignis/src/core.dart';
import 'package:ignis/src/inputs/nodes/input_node.dart';

/// A hit area that recognizes mouse hover.
///
/// Flutter's mouse tracker reports enter and exit as they happen, both on
/// pointer events and after every frame.
class HoverInput extends InputNode
    with Diagnosticable
    implements MouseTrackerAnnotation, HitTestTarget {
  /// How many pointers are over this node.
  int _pointers = 0;

  /// Whether a pointer is currently hovering this node.
  bool get isHovering => _pointers > 0;

  /// Emitted when a pointer starts hovering this node.
  final onHoverEnter = Signal0();

  /// Emitted when a pointer stops hovering this node.
  final onHoverExit = Signal0();

  HoverInput({
    super.shape,
    super.behavior,
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.enabled,
    super.priority,
    super.children,
  });

  @override
  void process(State state) {
    super.process(state);

    switch (state) {
      case Destroy():
        // The tracker skips the exit of a node no longer mounted.
        if (_pointers == 0) break;
        _pointers = 0;
        onHoverExit.emit();
    }
  }

  void _enter(PointerEnterEvent event) {
    _pointers += 1;
    if (_pointers > 1) return;
    onHoverEnter.emit();
  }

  void _exit(PointerExitEvent event) {
    if (_pointers == 0) return;
    _pointers -= 1;
    if (_pointers > 0) return;
    onHoverExit.emit();
  }

  @internal
  @override
  PointerEnterEventListener get onEnter => _enter;

  @internal
  @override
  PointerExitEventListener get onExit => _exit;

  @internal
  @override
  MouseCursor get cursor => MouseCursor.defer;

  @internal
  @override
  bool get validForMouseTracker => isMounted;

  @internal
  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    // Hover arrives through the mouse tracker instead.
  }
}
