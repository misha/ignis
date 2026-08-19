import 'package:flutter/services.dart';
import 'package:ignis/src/core.dart';

/// A pressed keyboard key and its modifier state.
///
/// This object is simultaneously what [KeyboardDevice] emits, and what handlers
/// use to match on keyboard events. Thus, the modifiers mean something
/// *slightly*  different when used as an "event" or a "matcher". This is
/// modestly unintuitive. Sorry!
///
/// When emitted by [KeyboardDevice] as an event, a modifier `bool?` means:
///
/// | Value     | Means                                                        |
/// |-----------|--------------------------------------------------------------|
/// | `true`    | The modifier was held as the key went down.                  |
/// | `false`   | The modifier was *not* held as the key went down.            |
/// | `null`    | The keyboard never uses this, it's always `true` or `false`. |
///
/// When used as a matcher on [Controls.bind], a modifier `bool?` means:
///
/// | Value     | Matches                                     |
/// |-----------|---------------------------------------------|
/// | `true`    | Only a press with the modifier held.        |
/// | `false`   | Only a press with the modifier released.    |
/// | `null`    | Any press, whether it was held or released. |
final class KeyPress implements ControlEvent {
  /// The key that went down.
  final LogicalKeyboardKey key;

  /// Whether either alt key must be held, released, or neither.
  final bool? alt;

  /// Whether either control key must be held, released, or neither.
  final bool? control;

  /// Whether either shift key must be held, released, or neither.
  final bool? shift;

  /// Whether either meta key must be held, released, or neither.
  final bool? meta;

  const KeyPress(
    this.key, {
    this.alt,
    this.control,
    this.shift,
    this.meta,
  });

  @override
  bool accepts(ControlEvent emitted) {
    if (emitted is! KeyPress) return false;
    if (key != emitted.key) return false;
    if (alt != null && alt != (emitted.alt ?? false)) return false;
    if (control != null && control != (emitted.control ?? false)) return false;
    if (shift != null && shift != (emitted.shift ?? false)) return false;
    if (meta != null && meta != (emitted.meta ?? false)) return false;
    return true;
  }

  @override
  bool operator ==(Object other) {
    return other is KeyPress &&
        other.key == key &&
        other.alt == alt &&
        other.control == control &&
        other.shift == shift &&
        other.meta == meta;
  }

  @override
  int get hashCode => Object.hash(key, alt, control, shift, meta);

  @override
  String toString() {
    final label = StringBuffer();
    if (control == true) label.write('ctrl+');
    if (alt == true) label.write('alt+');
    if (shift == true) label.write('shift+');
    if (meta == true) label.write('meta+');
    label.write(key.debugName ?? key.keyLabel);
    return label.toString();
  }
}

/// The hardware keyboard, as a control device.
///
/// TODO: Implement a `KeyRepeat` event, parameterized by this class.
final class KeyboardDevice extends ControlDevice {
  @override
  void start() => HardwareKeyboard.instance.addHandler(_handle);

  @override
  void stop() => HardwareKeyboard.instance.removeHandler(_handle);

  /// Turns a key down into a press, ignoring the platform's repeats so an
  /// action runs once per press.
  bool _handle(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final keyboard = HardwareKeyboard.instance;

    return emit(
      KeyPress(
        event.logicalKey,
        alt: keyboard.isAltPressed,
        control: keyboard.isControlPressed,
        shift: keyboard.isShiftPressed,
        meta: keyboard.isMetaPressed,
      ),
    );
  }
}
