import 'package:ignis/src/core.dart';
import 'package:ignis/src/devices/keyboard.dart';
import 'package:ignis/src/globals.dart';

/// Wires the engine's own debug controls to the keyboard for as long as this
/// node is mounted.
///
/// The default controls are as follows:
///
/// | Key | Parameter    | Does                                            |
/// |-----|--------------|-------------------------------------------------|
/// | F1  | [transforms] | Draws every drawn node's bounds.                |
/// | F2  | [collisions] | Draws every collider's hitbox.                  |
/// | F3  | [inputs]     | Draws every input node's hit area.              |
/// | F4  | [layouts]    | Draws every layout node's box.                  |
/// | F5  | [pause]      | Pauses and resumes the scene this node is in.   |
/// | F6  | [debug]      | Draws every wireframe at once, or none of them. |
///
/// Each of the first four toggles its own bit of [DebugMode], so they combine:
/// any set of wireframes draws at once, a second press takes one back out, and
/// the overlay is off once the last one is out. [debug] toggles every bit
/// together, so it fills the overlay from anywhere short of full and empties it
/// from there.
///
/// Every parameter is a set of matchers, so `DebugControlsNode(pause: const {})`
/// declines that one and keeps the rest, and passing your own remaps just it.
/// Unlike a declined control, an omitted one takes its default.
///
/// The default [priority] is lower than usual to ensure key presses prefer
/// actual game controls, if they overlap with the debug controls.
class DebugControlsNode extends Node {
  /// Toggles every drawn node's bounds.
  final Set<ControlEvent> transforms;

  /// Toggles every collider's hitbox.
  final Set<ControlEvent> collisions;

  /// Toggles every input node's hit area.
  final Set<ControlEvent> inputs;

  /// Toggles every layout node's box.
  final Set<ControlEvent> layouts;

  /// Pauses and resumes the scene this node is in.
  final Set<ControlEvent> pause;

  /// Toggles every wireframe at once.
  final Set<ControlEvent> debug;

  /// The groups gating every one of them, empty where nothing does.
  final Set<String> groups;

  DebugControlsNode({
    Set<ControlEvent>? transforms,
    Set<ControlEvent>? collisions,
    Set<ControlEvent>? inputs,
    Set<ControlEvent>? layouts,
    Set<ControlEvent>? pause,
    Set<ControlEvent>? debug,
    this.groups = const {'debug'},
    super.priority = -1000,
    super.enabled,
  }) : transforms = transforms ?? {const KeyPress(.f1)},
       collisions = collisions ?? {const KeyPress(.f2)},
       inputs = inputs ?? {const KeyPress(.f3)},
       layouts = layouts ?? {const KeyPress(.f4)},
       pause = pause ?? {const KeyPress(.f5)},
       debug = debug ?? {const KeyPress(.f6)};

  @override
  void build() {
    super.build();

    Ignis.controls.bind(
      (_) => Ignis.debug.toggle(.transforms),
      matchers: transforms,
      groups: groups,
    );

    Ignis.controls.bind(
      (_) => Ignis.debug.toggle(.collisions),
      matchers: collisions,
      groups: groups,
    );

    Ignis.controls.bind(
      (_) => Ignis.debug.toggle(.inputs),
      matchers: inputs,
      groups: groups,
    );

    Ignis.controls.bind(
      (_) => Ignis.debug.toggle(.layouts),
      matchers: layouts,
      groups: groups,
    );

    Ignis.controls.bind(
      (_) => scene.paused = !scene.paused,
      matchers: pause,
      groups: groups,
    );

    Ignis.controls.bind(
      (_) => Ignis.debug.toggle(.all),
      matchers: debug,
      groups: groups,
    );
  }
}
