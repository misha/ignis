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
  late List<ControlEvent> fired;

  setUp(() {
    fired = [];
    device = _FakeDevice();
    controls = Controls()..bind(fired.add, matchers: {const _ButtonPress(3)});
  });

  group('installing', () {
    test('starts the device and lists it', () {
      controls.install(device);

      expect(device.starts, 1);
      expect(device.isStarted, isTrue);
      expect(controls.devices, [device]);
    });

    test('the same device twice starts it once', () {
      controls
        ..install(device)
        ..install(device);

      expect(device.starts, 1);
      expect(controls.devices, hasLength(1));
    });
  });

  group('uninstalling', () {
    test('stops the device and drops it', () {
      controls
        ..install(device)
        ..uninstall(device);

      expect(device.stops, 1);
      expect(device.isStarted, isFalse);
      expect(controls.devices, isEmpty);
    });

    test('a device that was never installed does nothing', () {
      controls.uninstall(device);

      expect(device.stops, 0);
    });

    test('disposing stops every attached device', () {
      final other = _FakeDevice();

      controls
        ..install(device)
        ..install(other)
        ..dispose();

      expect(device.stops, 1);
      expect(other.stops, 1);
      expect(controls.devices, isEmpty);
    });
  });

  group('receiving', () {
    test('an event from a device the engine never heard of still runs', () {
      controls.install(device);

      expect(device.press([3]), isTrue);
      expect(fired.single, isA<_ButtonPress>());
    });

    test('one device event yielding several control events runs each', () {
      controls = Controls()
        ..bind(fired.add, matchers: {const _ButtonPress(3), const _ButtonPress(4)});
      controls.install(device);

      expect(device.press([3, 4]), isTrue);
      expect(fired, hasLength(2));
    });

    test('an event yielding nothing reports itself unhandled', () {
      controls.install(device);

      expect(device.press([]), isFalse);
      expect(fired, isEmpty);
    });

    test('an event nothing is bound to reports itself unhandled', () {
      controls.install(device);

      expect(device.press([4]), isFalse);
      expect(fired, isEmpty);
    });

    test('a device that was never started dispatches nothing', () {
      expect(device.press([3]), isFalse);
      expect(fired, isEmpty, reason: 'the base holds the dispatch until started');
    });

    test('an uninstalled device dispatches nothing', () {
      controls
        ..install(device)
        ..uninstall(device);

      expect(device.press([3]), isFalse);
      expect(fired, isEmpty);
    });
  });
}
