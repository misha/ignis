// SPDX-AI-Disclosure: none

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
/// | F1  | [spatial]    | Draws every spatial node's bounds.              |
/// | F2  | [collision]  | Draws every collider's hitbox.                  |
/// | F3  | [input]      | Draws every input node's hit area.              |
/// | F4  | [layout]     | Draws every layout node's box.                  |
/// | F5  | [pause]      | Pauses and resumes the scene this node is in.   |
/// | F6  | [clear]      | Clears the overlay, whatever it was drawing.    |
///
/// Every parameter is a set of matchers, so `DebugControlsNode(pause: const {})`
/// declines that one and keeps the rest, and passing your own remaps just it.
/// Unlike a declined control, an omitted one takes its default.
///
/// The default [priority] is lower than usual to ensure key presses prefer
/// actual game controls, if they overlap with the debug controls.
class DebugControlsNode extends Node {
  /// Toggles every spatial node's bounds.
  final Set<ControlEvent> spatial;

  /// Toggles every collider's hitbox.
  final Set<ControlEvent> collision;

  /// Toggles every input node's hit area.
  final Set<ControlEvent> input;

  /// Toggles every layout node's box.
  final Set<ControlEvent> layout;

  /// Pauses and resumes the scene this node is in.
  final Set<ControlEvent> pause;

  /// Clears the overlay, whatever it was drawing.
  final Set<ControlEvent> clear;

  /// The groups gating every one of them, empty where nothing does.
  final Set<String> groups;

  DebugControlsNode({
    Set<ControlEvent>? spatial,
    Set<ControlEvent>? collision,
    Set<ControlEvent>? input,
    Set<ControlEvent>? layout,
    Set<ControlEvent>? pause,
    Set<ControlEvent>? clear,
    this.groups = const {'debug'},
    super.priority = -1000,
    super.enabled,
  }) : spatial = spatial ?? {const KeyPress(.f1)},
       collision = collision ?? {const KeyPress(.f2)},
       input = input ?? {const KeyPress(.f3)},
       layout = layout ?? {const KeyPress(.f4)},
       pause = pause ?? {const KeyPress(.f5)},
       clear = clear ?? {const KeyPress(.f6)};

  @override
  void build() {
    super.build();

    Ignis.controls.bind(
      (_) => Ignis.debug.toggle(.spatial),
      matchers: spatial,
      groups: groups,
    );

    Ignis.controls.bind(
      (_) => Ignis.debug.toggle(.collision),
      matchers: collision,
      groups: groups,
    );

    Ignis.controls.bind(
      (_) => Ignis.debug.toggle(.input),
      matchers: input,
      groups: groups,
    );

    Ignis.controls.bind(
      (_) => Ignis.debug.toggle(.layout),
      matchers: layout,
      groups: groups,
    );

    Ignis.controls.bind(
      (_) => scene.paused = !scene.paused,
      matchers: pause,
      groups: groups,
    );

    Ignis.controls.bind(
      (_) => Ignis.debug.mode = null,
      matchers: clear,
      groups: groups,
    );
  }
}
