// SPDX-AI-Disclosure: none

import 'package:ignis/src/controls.dart';
import 'package:ignis/src/core.dart';
import 'package:ignis/src/devices/keyboard.dart';
import 'package:ignis/src/globals.dart';
import 'package:ignis/src/message.dart';

enum _Action {
  spatial,
  collision,
  input,
  layout,
  pause,
  clear,
}

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
/// Every parameter is a set of matchers. Pass `const {}` to decline a control,
/// your own set to remap it, or omit it for the default.
///
/// The default [priority] is lower than usual to ensure key presses prefer
/// actual game controls, if they overlap with the debug controls.
class DebugControlsNode extends Node {
  /// Toggles every spatial node's bounds.
  final Set<Trigger> spatial;

  /// Toggles every collider's hitbox.
  final Set<Trigger> collision;

  /// Toggles every input node's hit area.
  final Set<Trigger> input;

  /// Toggles every layout node's box.
  final Set<Trigger> layout;

  /// Pauses and resumes the scene this node is in.
  final Set<Trigger> pause;

  /// Clears the overlay, whatever it was drawing.
  final Set<Trigger> clear;

  /// The groups gating all of them, if any.
  final Set<String> groups;

  DebugControlsNode({
    Set<Trigger>? spatial,
    Set<Trigger>? collision,
    Set<Trigger>? input,
    Set<Trigger>? layout,
    Set<Trigger>? pause,
    Set<Trigger>? clear,
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
  void process(Message message) {
    super.process(message);

    switch (message) {
      case Build():
        Ignis.controls.bind(
          this,
          _Action.spatial,
          matchers: spatial,
          groups: groups,
        );

        Ignis.controls.bind(
          this,
          _Action.collision,
          matchers: collision,
          groups: groups,
        );

        Ignis.controls.bind(
          this,
          _Action.input,
          matchers: input,
          groups: groups,
        );

        Ignis.controls.bind(
          this,
          _Action.layout,
          matchers: layout,
          groups: groups,
        );

        Ignis.controls.bind(
          this,
          _Action.pause,
          matchers: pause,
          groups: groups,
        );

        Ignis.controls.bind(
          this,
          _Action.clear,
          matchers: clear,
          groups: groups,
        );

      case Destroy():
        Ignis.controls.release(this);

      case Control(:final action):
        switch (action) {
          case _Action.spatial:
            Ignis.debug.toggle(.spatial);

          case _Action.collision:
            Ignis.debug.toggle(.collision);

          case _Action.input:
            Ignis.debug.toggle(.input);

          case _Action.layout:
            Ignis.debug.toggle(.layout);

          case _Action.pause:
            scene.paused = !scene.paused;

          case _Action.clear:
            Ignis.debug.mode = null;
        }
    }
  }
}
