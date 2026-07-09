import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';
import 'package:leak_tracker/leak_tracker.dart';

import 'support/test_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Ignis.cache.clear();
  });

  test('loads a single asset with the given loader', () async {
    final preload = Preload();
    preload.path(.image(), 'test/assets/fire.png');
    await preload.run();

    expect(Ignis.cache.retrieve('test/assets/fire.png'), isA<Image>());
    expect(preload.total, 1);
    expect(preload.completed, 1);
    expect(preload.progress, 1);
    expect(preload.done, isTrue);
  });

  test('loads multiple assets from paths', () async {
    final preload = Preload();

    preload.paths(.image(), [
      'test/assets/fire.png',
      'test/assets/fire.gif',
    ]);

    await preload.run();

    expect(preload.total, 2);
    expect(preload.completed, 2);
    expect(Ignis.cache.contains('test/assets/fire.png'), isTrue);
    expect(Ignis.cache.contains('test/assets/fire.gif'), isTrue);
  });

  test('loads assets discovered from a manifest', () async {
    final bundle = TestBundle([
      'test/assets/fire.png',
      'test/assets/fire.gif',
    ]);

    final preload = Preload();
    preload.manifest(.image(), bundle: bundle);
    await preload.run();

    expect(Ignis.cache.contains('test/assets/fire.png'), isTrue);
    expect(Ignis.cache.contains('test/assets/fire.gif'), isTrue);
  });

  test('decodes JSON assets into the cache', () async {
    final preload = Preload();
    preload.path(.json(), 'test/assets/data.json');
    await preload.run();
    expect(Ignis.cache.retrieve('test/assets/data.json'), {'hello': 'world'});
  });

  test('compiles shader assets into the cache', () async {
    final preload = Preload();
    preload.path(.shader(), 'test/shaders/sample.frag');
    await preload.run();
    expect(Ignis.cache.retrieve('test/shaders/sample.frag'), isA<FragmentProgram>());
  });

  test('routes assets to matching loaders using prefix and extension filters', () async {
    final preload = Preload();
    final loader = ImageLoader()
      ..prefix('test/')
      ..extensions(['png']);

    preload.paths(loader, [
      'test/assets/fire.png',
      'test/assets/data.json',
      'test/shaders/sample.frag',
    ]);

    await preload.run();
    expect(Ignis.cache.contains('test/assets/fire.png'), isTrue);
    expect(Ignis.cache.contains('test/assets/data.json'), isFalse);
    expect(Ignis.cache.contains('test/shaders/sample.frag'), isFalse);
  });

  test('reports incremental progress as assets complete', () async {
    final preload = Preload();

    preload.paths(.image(), [
      'test/assets/fire.png',
      'test/assets/fire.gif',
    ]);

    final updates = <double>[];
    preload.addListener(() => updates.add(preload.progress));
    await preload.run();

    expect(updates, isNotEmpty);
    expect(updates.last, 1);
    expect(preload.done, isTrue);
  });

  test('loads into a custom cache instead of the global one', () async {
    final cache = Cache();
    final preload = Preload(cache: cache);
    preload.path(.image(), 'test/assets/fire.png');
    await preload.run();

    expect(cache.contains('test/assets/fire.png'), isTrue);
    expect(Ignis.cache.contains('test/assets/fire.png'), isFalse);
  });

  test('rejects scheduling once the preload has started', () async {
    final preload = Preload();
    preload.path(.image(), 'test/assets/fire.png');
    final future = preload.run();
    expect(() => preload.path(.image(), 'test/assets/fire.gif'), throwsStateError);
    expect(() => preload.paths(.image(), ['test/assets/fire.gif']), throwsStateError);
    expect(() => preload.manifest(.image()), throwsStateError);
    expect(() => preload.run(), throwsStateError);
    await future;
  });

  test('rejects running twice', () async {
    final preload = Preload();
    preload.path(.image(), 'test/assets/fire.png');
    await preload.run();
    expect(() => preload.run(), throwsStateError);
  });

  test('disposes its pool after run completes', () async {
    void forwardToLeakTracker(ObjectEvent event) => LeakTracking.dispatchObjectEvent(event.toMap());
    FlutterMemoryAllocations.instance.addListener(forwardToLeakTracker);
    LeakTracking.start();

    final preload = Preload();
    var triggers = 0;
    preload.addListener(() => triggers += 1);
    preload.path(.noop(), 'test/assets/fire.png');

    await preload.run();
    await preload.dispose();

    LeakTracking.declareNotDisposedObjectsAsLeaks();
    final leaks = await LeakTracking.collectLeaks();
    LeakTracking.stop();
    FlutterMemoryAllocations.instance.removeListener(forwardToLeakTracker);

    expect(leaks.total, 0);
    expect(triggers, 2);
  });
}
