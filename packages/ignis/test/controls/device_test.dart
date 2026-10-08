import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/test_device.dart';
import '../support/test_sink.dart';

void main() {
  late Controls controls;
  late TestDevice device;
  late TestSink sink;
  late Scene scene;

  setUp(() {
    sink = TestSink();
    scene = sink.mount();
    device = TestDevice();
    controls = Controls()
      ..bind(
        sink,
        'press',
        matchers: {
          const ButtonTrigger(3),
        },
      );
  });

  tearDown(() => scene.destroy());

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
      expect(sink.of<Control>().single.trigger, isA<ButtonTrigger>());
    });

    test('one device event yielding several triggers runs each', () {
      controls = Controls()
        ..bind(
          sink,
          'press',
          matchers: {
            const ButtonTrigger(3),
            const ButtonTrigger(4),
          },
        );

      controls.install(device);

      expect(device.press([3, 4]), isTrue);
      expect(sink.of<Control>(), hasLength(2));
    });

    test('an event yielding nothing reports itself unhandled', () {
      controls.install(device);

      expect(device.press([]), isFalse);
      expect(sink.received, isEmpty);
    });

    test('an event nothing is bound to reports itself unhandled', () {
      controls.install(device);

      expect(device.press([4]), isFalse);
      expect(sink.received, isEmpty);
    });

    test('a device that was never started dispatches nothing', () {
      expect(device.press([3]), isFalse);
      expect(sink.received, isEmpty, reason: 'the base holds the dispatch until started');
    });

    test('an uninstalled device dispatches nothing', () {
      controls
        ..install(device)
        ..uninstall(device);

      expect(device.press([3]), isFalse);
      expect(sink.received, isEmpty);
    });
  });
}
