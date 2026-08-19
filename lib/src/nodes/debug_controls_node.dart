import 'package:ignis/src/core.dart';
import 'package:ignis/src/devices/keyboard.dart';
import 'package:ignis/src/globals.dart';

/// Wires the engine's own debug controls to the keyboard for as long as this
/// node is mounted.
///
/// The default controls are as follows:
///
/// | Key      | Parameter   | Does                                          |
/// |----------|-------------|-----------------------------------------------|
/// | F1       | [pause]     | Freezes and resumes the scene this node is in |
/// | F2       | [cycle]     | Steps the overlay on, then stage by stage     |
/// | Shift-F2 | [cycleBack] | Steps the overlay back a stage                |
/// | F3       | [off]       | Turns the overlay off                         |
///
/// [cycle] walks [DebugMode], which opens on every wireframe at once and then
/// takes them one at a time, so the first press shows the lot and the next
/// narrows it. The cycle never passes through off: [off] is the single press out
/// of it, from wherever it stopped.
///
/// One key carries both directions because [cycle] asks for shift released and
/// [cycleBack] asks for it held, so a press answers exactly one of them.
///
/// Every parameter is a set of matchers, so `DebugControlsNode(off: const {})`
/// declines that one and keeps the rest, and passing your own remaps just it.
/// Unlike a declined control, an omitted one takes its default.
///
/// The default [priority] is lower than usual to ensure key presses prefer
/// actual game controls, if they overlap with the debug controls.
class DebugControlsNode extends Node {
  /// Pauses and resumes the scene this node is in.
  final Set<ControlEvent> pause;

  /// Steps the overlay to its next mode, or switches it on.
  final Set<ControlEvent> cycle;

  /// Steps the overlay back a mode.
  final Set<ControlEvent> cycleBack;

  /// Turns the overlay off.
  final Set<ControlEvent> off;

  /// The groups gating every one of them, empty where nothing does.
  final Set<String> groups;

  DebugControlsNode({
    Set<ControlEvent>? pause,
    Set<ControlEvent>? cycle,
    Set<ControlEvent>? cycleBack,
    Set<ControlEvent>? off,
    this.groups = const {'debug'},
    super.priority = -1000,
    super.enabled,
  }) : pause = pause ?? {const KeyPress(.f1)},
       cycle = cycle ?? {const KeyPress(.f2, shift: false)},
       cycleBack = cycleBack ?? {const KeyPress(.f2, shift: true)},
       off = off ?? {const KeyPress(.f3)};

  @override
  void build() {
    super.build();

    Ignis.controls.bind(
      (_) => scene.paused = !scene.paused,
      matchers: pause,
      groups: groups,
    );

    Ignis.controls.bind(
      (_) => Ignis.debug.next(),
      matchers: cycle,
      groups: groups,
    );

    Ignis.controls.bind(
      (_) => Ignis.debug.previous(),
      matchers: cycleBack,
      groups: groups,
    );

    Ignis.controls.bind(
      (_) => Ignis.debug.mode = null,
      matchers: off,
      groups: groups,
    );
  }
}
