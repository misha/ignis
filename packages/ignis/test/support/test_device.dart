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
  /// any number of triggers.
  bool press(List<int> buttons) {
    var handled = false;

    for (final button in buttons) {
      if (emit(ButtonTrigger(button))) handled = true;
    }

    return handled;
  }
}

/// Matches its own kind.
final class TestTrigger implements Trigger {
  const TestTrigger();

  @override
  bool accepts(Trigger trigger) => trigger is TestTrigger;
}

/// A trigger carrying a [name], matching the one that shares it.
final class NamedTrigger implements Trigger {
  final String name;

  const NamedTrigger(this.name);

  @override
  bool accepts(Trigger trigger) => this == trigger;

  @override
  bool operator ==(Object other) =>
      other is NamedTrigger && //
      other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => name;
}

/// A non-keyboard trigger.
final class ButtonTrigger implements Trigger {
  final int button;

  const ButtonTrigger(this.button);

  @override
  bool accepts(Trigger trigger) {
    return trigger is ButtonTrigger && trigger.button == button;
  }

  @override
  String toString() => 'button$button';
}
