import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';
import 'package:leak_tracker/leak_tracker.dart';

import 'support/test_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Ignis.cache.clear();
    Ignis.bundle = rootBundle;
  });

  test('loads a single asset with the registered loader', () async {
    final preload = Preload();
    preload.loader(.image());
    final request = preload.load(paths: ['test/assets/fire.png']);
    await request;

    expect(Ignis.cache.retrieve('test/assets/fire.png'), isA<Image>());
    expect(request.total, 1);
    expect(request.completed, 1);
    expect(request.progress, 1);
    expect(request.done, isTrue);
    request.dispose();
  });

  test('loads multiple assets from paths', () async {
    final preload = Preload();
    preload.loader(.image());

    final request = preload.load(
      paths: [
        'test/assets/fire.png',
        'test/assets/fire.gif',
      ],
    );

    await request;

    expect(request.total, 2);
    expect(request.completed, 2);
    expect(Ignis.cache.contains('test/assets/fire.png'), isTrue);
    expect(Ignis.cache.contains('test/assets/fire.gif'), isTrue);
    request.dispose();
  });

  test('loads assets discovered from a manifest', () async {
    Ignis.bundle = TestBundle([
      'test/assets/fire.png',
      'test/assets/fire.gif',
    ]);

    final preload = Preload();
    preload.loader(.image());
    final request = preload.load(manifest: true);
    await request;

    expect(request.total, 2);
    expect(Ignis.cache.contains('test/assets/fire.png'), isTrue);
    expect(Ignis.cache.contains('test/assets/fire.gif'), isTrue);
    request.dispose();
  });

  test('combines a manifest with explicit paths', () async {
    Ignis.bundle = TestBundle(['test/assets/fire.png']);

    final preload = Preload();
    preload.loader(.image());

    final request = preload.load(
      manifest: true,
      paths: ['test/assets/fire.gif'],
    );

    await request;

    expect(request.total, 2);
    expect(Ignis.cache.contains('test/assets/fire.png'), isTrue);
    expect(Ignis.cache.contains('test/assets/fire.gif'), isTrue);
    request.dispose();
  });

  test('decodes JSON assets into the cache', () async {
    final preload = Preload();
    preload.loader(.json());
    final request = preload.load(paths: ['test/assets/data.json']);
    await request;

    expect(Ignis.cache.retrieve('test/assets/data.json'), {'hello': 'world'});
    request.dispose();
  });

  test('routes assets to matching loaders using prefix and extension filters', () async {
    final preload = Preload();

    preload.loader(
      ImageLoader()
        ..prefix('test/')
        ..extensions(['png']),
    );

    final request = preload.load(
      paths: [
        'test/assets/fire.png',
        'test/assets/data.json',
      ],
    );

    await request;

    expect(Ignis.cache.contains('test/assets/fire.png'), isTrue);
    expect(Ignis.cache.contains('test/assets/data.json'), isFalse);
    request.dispose();
  });

  test('feeds each asset through every registered loader', () async {
    final preload = Preload();
    preload.loader(.image()..extensions(['.png']));
    preload.loader(.json()..extensions(['.json']));

    final request = preload.load(
      paths: [
        'test/assets/fire.png',
        'test/assets/data.json',
      ],
    );

    await request;

    expect(Ignis.cache.retrieve('test/assets/fire.png'), isA<Image>());
    expect(Ignis.cache.retrieve('test/assets/data.json'), {'hello': 'world'});
    request.dispose();
  });

  test('notifies its listeners as assets complete', () async {
    final preload = Preload();
    preload.loader(.image());

    final request = preload.load(
      paths: [
        'test/assets/fire.png',
        'test/assets/fire.gif',
      ],
    );

    expect(request.done, isFalse);
    expect(request.progress, 0);

    final updates = <double>[];
    request.addListener(() => updates.add(request.progress));
    await request;

    expect(updates, isNotEmpty);
    expect(updates.last, 1);
    expect(request.progress, 1);
    expect(request.done, isTrue);
    request.dispose();
  });

  test('grows its total once a manifest is read', () async {
    Ignis.bundle = TestBundle([
      'test/assets/fire.png',
      'test/assets/fire.gif',
    ]);

    final preload = Preload();
    preload.loader(.image());

    final request = preload.load(manifest: true);
    expect(request.total, 0);

    final totals = <int>[];
    request.addListener(() => totals.add(request.total));
    await request;

    expect(totals.first, 2, reason: 'the manifest should report before loading');
    expect(request.total, 2);
    request.dispose();
  });

  test('stops notifying once disposed mid-load', () async {
    final preload = Preload();
    preload.loader(.image());

    final request = preload.load(
      paths: [
        'test/assets/fire.png',
        'test/assets/fire.gif',
      ],
    );

    var triggers = 0;
    request.addListener(() => triggers += 1);
    request.dispose();
    await request;

    expect(triggers, 0);
    expect(request.done, isTrue);
  });

  test('loads into a custom cache instead of the global one', () async {
    final cache = Cache();
    final preload = Preload(cache: cache);
    preload.loader(.image());
    final request = preload.load(paths: ['test/assets/fire.png']);
    await request;

    expect(cache.contains('test/assets/fire.png'), isTrue);
    expect(Ignis.cache.contains('test/assets/fire.png'), isFalse);
    request.dispose();
  });

  test('runs overlapping requests without contention', () async {
    final preload = Preload();
    preload.loader(.image());

    final first = preload.load(paths: ['test/assets/fire.png']);
    final second = preload.load(paths: ['test/assets/fire.gif']);
    final third = preload.load(paths: ['test/assets/fire.png']);

    await Future.wait([first, second, third]);

    expect(first.total, 1);
    expect(second.total, 1);
    expect(third.total, 1);
    expect(Ignis.cache.contains('test/assets/fire.png'), isTrue);
    expect(Ignis.cache.contains('test/assets/fire.gif'), isTrue);

    first.dispose();
    second.dispose();
    third.dispose();
  });

  test('replaces a cached asset on a later request', () async {
    final preload = Preload();
    preload.loader(.image());
    final first = preload.load(paths: ['test/assets/fire.png']);
    await first;

    final image = Ignis.cache.retrieve<Image>('test/assets/fire.png');
    final second = preload.load(paths: ['test/assets/fire.png']);
    await second;

    expect(Ignis.cache.retrieve<Image>('test/assets/fire.png'), isNot(same(image)));

    first.dispose();
    second.dispose();
  });

  test('leaves an asset the loaders reject alone', () async {
    final preload = Preload();
    preload.loader(.image()..extensions(['.png']));
    final request = preload.load(paths: ['test/assets/data.json']);
    await request;

    expect(Ignis.cache.contains('test/assets/data.json'), isFalse);
    expect(request.completed, 1);
    request.dispose();
  });

  test('applies only the loaders registered when the request started', () async {
    final preload = Preload();
    preload.loader(.image()..extensions(['.png']));
    final request = preload.load(paths: ['test/assets/data.json']);
    preload.loader(.json());
    await request;

    expect(Ignis.cache.contains('test/assets/data.json'), isFalse);
    request.dispose();
  });

  test('rejects loading once disposed', () async {
    final preload = Preload();
    preload.loader(.image());
    await preload.dispose();

    final request = preload.load(paths: ['test/assets/fire.png']);
    await expectLater(request, throwsStateError);
    request.dispose();
  });

  test('leaves no undisposed request behind', () async {
    void forwardToLeakTracker(ObjectEvent event) => LeakTracking.dispatchObjectEvent(event.toMap());
    FlutterMemoryAllocations.instance.addListener(forwardToLeakTracker);
    LeakTracking.start();

    final preload = Preload();
    preload.loader(.noop());
    final request = preload.load(paths: ['test/assets/fire.png']);
    // A listener is what registers the notifier with the tracker, so an
    // undisposed request only shows up as a leak once something listens.
    request.addListener(() {});
    await request;
    request.dispose();
    await preload.dispose();

    LeakTracking.declareNotDisposedObjectsAsLeaks();
    final leaks = await LeakTracking.collectLeaks();
    LeakTracking.stop();
    FlutterMemoryAllocations.instance.removeListener(forwardToLeakTracker);

    expect(leaks.total, 0);
  });
}
