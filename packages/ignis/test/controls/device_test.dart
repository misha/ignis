import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/test_device.dart';

void main() {
  late Controls controls;
  late TestDevice device;
  late List<ControlEvent> fired;

  setUp(() {
    fired = [];
    device = TestDevice();
    controls = Controls()
      ..bind(
        fired.add,
        matchers: {
          const ButtonEvent(3),
        },
      );
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
      final other = TestDevice();

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
      expect(fired.single, isA<ButtonEvent>());
    });

    test('one device event yielding several control events runs each', () {
      controls = Controls()
        ..bind(
          fired.add,
          matchers: {
            const ButtonEvent(3),
            const ButtonEvent(4),
          },
        );

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
