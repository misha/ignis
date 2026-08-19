import 'package:ignis/src/core.dart';
import 'package:ignis/src/devices/keyboard.dart';
import 'package:ignis/src/globals.dart';

/// The engine's own actions, bound by [DebugControlsNode].
enum DebugAction {
  /// Freezes or resumes the current scene.
  pause,

  /// Steps the debug overlay to its next stage, or switches it on.
  cycleNext,

  /// Steps the debug overlay back a stage.
  cyclePrevious,

  /// Turns the debug overlay off.
  off,
}

/// Wires [DebugAction] to the keyboard for as long as this node is mounted.
///
/// The default controls are as follows:
///
/// | Key      | Parameter       | Action                                     |
/// |----------|-----------------|--------------------------------------------|
/// | F1       | [pause]         | Pauses and resumes the scene.              |
/// | F2       | [cycleNext]     | Steps the overlay on, then stage by stage. |
/// | Shift-F2 | [cyclePrevious] | Steps the overlay back a stage.            |
/// | F3       | [off]           | Turns the overlay off.                     |
///
/// [cycleNext] walks [DebugMode], which starts by showing all the wireframes
/// at once, and then takes them one at a time. The cycle never passes through
/// off; instead, [off] is a single, separate key press.
///
/// Pass `null` to any press to leave it unbound. Note the controls will still
/// perform the matching debug action when a [DebugAction] is *manually* fired.
///
/// The default [priority] is lower than usual to ensure key presses prefer
/// actual game controls, if they overlap with the debug controls.
class DebugControlsNode extends Node {
  /// Pauses and resumes the scene this node is in.
  final KeyPress? pause;

  /// Steps the overlay to its next stage, or switches it on.
  final KeyPress? cycleNext;

  /// Steps the overlay back a stage.
  final KeyPress? cyclePrevious;

  /// Turns the overlay off.
  final KeyPress? off;

  DebugControlsNode({
    this.pause = const KeyPress(.f1),
    this.cycleNext = const KeyPress(.f2, shift: false),
    this.cyclePrevious = const KeyPress(.f2, shift: true),
    this.off = const KeyPress(.f3),
    super.priority = -1000,
    super.enabled,
  });

  @override
  void build() {
    super.build();

    Ignis.controls.claim(
      DebugAction.pause,
      (_) => scene.paused = !scene.paused,
      matchers: {?pause},
    );

    Ignis.controls.claim(
      DebugAction.cycleNext,
      (_) => Ignis.debug.next(),
      matchers: {?cycleNext},
    );

    Ignis.controls.claim(
      DebugAction.cyclePrevious,
      (_) => Ignis.debug.previous(),
      matchers: {?cyclePrevious},
    );

    Ignis.controls.claim(
      DebugAction.off,
      (_) => Ignis.debug.mode = null,
      matchers: {?off},
    );
  }
}
