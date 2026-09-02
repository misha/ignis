import 'package:ignis/ignis.dart';

/// A device the engine knows nothing about, whose events are the buttons that
/// went down together, so one event can stand for any number of triggers.
final class TestDevice extends ControlDevice {
  int starts = 0;
  int stops = 0;

  @override
  void start() => starts += 1;

  @override
  void stop() => stops += 1;

  /// Drives the device by hand, standing in for a platform listener.
  ///
  /// One call stands for one of the device's own events, which may turn into
  /// any number of control events.
  bool press(List<int> buttons) {
    var handled = false;

    for (final button in buttons) {
      if (emit(ButtonEvent(button))) handled = true;
    }

    return handled;
  }
}

/// The simplest event there is: it matches its own kind.
final class TestEvent implements ControlEvent {
  const TestEvent();

  @override
  bool accepts(ControlEvent emitted) => emitted is TestEvent;
}

/// An event carrying a [name], matching the one that shares it.
final class NamedEvent implements ControlEvent {
  final String name;

  const NamedEvent(this.name);

  @override
  bool accepts(ControlEvent emitted) => this == emitted;

  @override
  bool operator ==(Object other) =>
      other is NamedEvent && //
      other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => name;
}

/// An event no keyboard could produce, to prove dispatch never assumes one.
final class ButtonEvent implements ControlEvent {
  final int button;

  const ButtonEvent(this.button);

  @override
  bool accepts(ControlEvent emitted) {
    return emitted is ButtonEvent && emitted.button == button;
  }

  @override
  String toString() => 'button$button';
}
