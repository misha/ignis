import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

/// An event no keyboard could produce, to prove dispatch never assumes one.
final class _ButtonPress implements ControlEvent {
  final int button;

  const _ButtonPress(this.button);

  @override
  bool accepts(ControlEvent emitted) {
    return emitted is _ButtonPress && emitted.button == button;
  }
}

/// A device the engine knows nothing about, whose events are the buttons that
/// went down together, so one event can stand for any number of triggers.
final class _FakeDevice extends ControlDevice {
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
      if (emit(_ButtonPress(button))) handled = true;
    }

    return handled;
  }
}

void main() {
  late Controls controls;
  late _FakeDevice device;
  late List<ControlReport> fired;

  setUp(() {
    fired = [];
    device = _FakeDevice();

    controls = Controls()
      ..bind('fire', {const _ButtonPress(3)})
      ..claim('fire', fired.add);
  });

  group('attaching', () {
    test('starts the device and lists it', () {
      controls.attach(device);

      expect(device.starts, 1);
      expect(device.isStarted, isTrue);
      expect(controls.devices, [device]);
    });

    test('the same device twice starts it once', () {
      controls
        ..attach(device)
        ..attach(device);

      expect(device.starts, 1);
      expect(controls.devices, hasLength(1));
    });
  });

  group('detaching', () {
    test('stops the device and drops it', () {
      controls
        ..attach(device)
        ..detach(device);

      expect(device.stops, 1);
      expect(device.isStarted, isFalse);
      expect(controls.devices, isEmpty);
    });

    test('a device that was never attached does nothing', () {
      controls.detach(device);

      expect(device.stops, 0);
    });

    test('disposing stops every attached device', () {
      final other = _FakeDevice();

      controls
        ..attach(device)
        ..attach(other)
        ..dispose();

      expect(device.stops, 1);
      expect(other.stops, 1);
      expect(controls.devices, isEmpty);
    });
  });

  group('receiving', () {
    test('an event from a device the engine never heard of still runs', () {
      controls.attach(device);

      expect(device.press([3]), isTrue);
      expect(fired.single.event, isA<_ButtonPress>());
    });

    test('one event yielding several triggers runs each of them', () {
      controls
        ..bind('fire', {const _ButtonPress(3), const _ButtonPress(4)})
        ..attach(device);

      expect(device.press([3, 4]), isTrue);
      expect(fired, hasLength(2));
    });

    test('an event yielding nothing reports itself unhandled', () {
      controls.attach(device);

      expect(device.press([]), isFalse);
      expect(fired, isEmpty);
    });

    test('an event nothing is bound to reports itself unhandled', () {
      controls.attach(device);

      expect(device.press([4]), isFalse);
      expect(fired, isEmpty);
    });

    test('a device that was never started dispatches nothing', () {
      expect(device.press([3]), isFalse);
      expect(fired, isEmpty, reason: 'the base holds the dispatch until started');
    });

    test('a detached device dispatches nothing', () {
      controls
        ..attach(device)
        ..detach(device);

      expect(device.press([3]), isFalse);
      expect(fired, isEmpty);
    });
  });
}
