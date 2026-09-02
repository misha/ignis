import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';
import 'package:leak_tracker/leak_tracker.dart';

import 'support/test_loader.dart';
import 'support/test_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Ignis.cache.clear();
    Ignis.bundle = TestBundle();
  });

  test('loads a single asset with the registered loader', () async {
    final preload = Preload();
    preload.register(ImageLoader());
    final request = preload.load(paths: ['test/assets/fire.png']);
    final snapshot = await request;

    expect(snapshot.succeeded, isTrue);
    expect(Ignis.cache.retrieve('test/assets/fire.png'), isA<Image>());
    expect(request.value.total, 1);
    expect(request.value.completed, 1);
    expect(request.value.progress, 1);
    expect(request.value.done, isTrue);
    request.dispose();
  });

  test('loads multiple assets from paths', () async {
    final preload = Preload();
    preload.register(ImageLoader());

    final request = preload.load(
      paths: [
        'test/assets/fire.png',
        'test/assets/fire.gif',
      ],
    );

    await request;

    expect(request.value.total, 2);
    expect(request.value.completed, 2);
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
    preload.register(ImageLoader());
    final request = preload.load(manifest: true);
    await request;

    expect(request.value.total, 2);
    expect(Ignis.cache.contains('test/assets/fire.png'), isTrue);
    expect(Ignis.cache.contains('test/assets/fire.gif'), isTrue);
    request.dispose();
  });

  test('combines a manifest with explicit paths', () async {
    Ignis.bundle = TestBundle(['test/assets/fire.png']);

    final preload = Preload();
    preload.register(ImageLoader());

    final request = preload.load(
      manifest: true,
      paths: ['test/assets/fire.gif'],
    );

    await request;

    expect(request.value.total, 2);
    expect(Ignis.cache.contains('test/assets/fire.png'), isTrue);
    expect(Ignis.cache.contains('test/assets/fire.gif'), isTrue);
    request.dispose();
  });

  test('decodes JSON assets into the cache', () async {
    final preload = Preload();
    preload.register(JsonLoader());
    final request = preload.load(paths: ['test/assets/data.json']);
    await request;

    expect(Ignis.cache.retrieve('test/assets/data.json'), {'hello': 'world'});
    request.dispose();
  });

  test('routes assets to matching loaders using prefix and extension filters', () async {
    final preload = Preload();

    preload.register(
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
    preload.register(ImageLoader()..extensions(['.png']));
    preload.register(JsonLoader()..extensions(['.json']));

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
    preload.register(ImageLoader());

    final request = preload.load(
      paths: [
        'test/assets/fire.png',
        'test/assets/fire.gif',
      ],
    );

    expect(request.value.done, isFalse);
    expect(request.value.progress, 0);

    final updates = <double>[];
    request.addListener(() => updates.add(request.value.progress));
    await request;

    expect(updates, isNotEmpty);
    expect(updates.last, 1);
    expect(request.value.progress, 1);
    expect(request.value.done, isTrue);
    request.dispose();
  });

  test('grows its total once a manifest is read', () async {
    Ignis.bundle = TestBundle([
      'test/assets/fire.png',
      'test/assets/fire.gif',
    ]);

    final preload = Preload();
    preload.register(ImageLoader());

    final request = preload.load(manifest: true);
    expect(request.value.total, 0);

    final totals = <int>[];
    request.addListener(() => totals.add(request.value.total));
    await request;

    expect(totals.first, 2, reason: 'the manifest should report before loading');
    expect(request.value.total, 2);
    request.dispose();
  });

  test('runs overlapping requests without contention', () async {
    final preload = Preload();
    preload.register(ImageLoader());

    final first = preload.load(paths: ['test/assets/fire.png']);
    final second = preload.load(paths: ['test/assets/fire.gif']);
    final third = preload.load(paths: ['test/assets/fire.png']);

    await Future.wait([first, second, third]);

    expect(first.value.total, 1);
    expect(second.value.total, 1);
    expect(third.value.total, 1);
    expect(Ignis.cache.contains('test/assets/fire.png'), isTrue);
    expect(Ignis.cache.contains('test/assets/fire.gif'), isTrue);

    first.dispose();
    second.dispose();
    third.dispose();
  });

  test('replaces a cached asset on a later request', () async {
    final preload = Preload();
    preload.register(ImageLoader());
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
    preload.register(ImageLoader()..extensions(['.png']));
    final request = preload.load(paths: ['test/assets/data.json']);
    await request;

    expect(Ignis.cache.contains('test/assets/data.json'), isFalse);
    expect(request.value.completed, 1);
    request.dispose();
  });

  test('applies only the loaders registered when the request started', () async {
    final preload = Preload();
    preload.register(ImageLoader()..extensions(['.png']));
    final request = preload.load(paths: ['test/assets/data.json']);
    preload.register(JsonLoader());
    await request;

    expect(Ignis.cache.contains('test/assets/data.json'), isFalse);
    request.dispose();
  });

  test('runs a one-off load and releases everything', () async {
    final request = Preload.run(
      loaders: [
        ImageLoader()..extensions(['.png']),
      ],
      paths: [
        'test/assets/fire.png',
        'test/assets/data.json',
      ],
    );

    await request;

    expect(Ignis.cache.retrieve('test/assets/fire.png'), isA<Image>());
    expect(Ignis.cache.contains('test/assets/data.json'), isFalse);
    expect(request.value.total, 2);
    expect(request.value.done, isTrue);

    // The request disposed itself on the way out, so listening now throws.
    expect(() => request.addListener(() {}), throwsFlutterError);
  });

  test('reports progress on a one-off load while it runs', () async {
    final request = Preload.run(loaders: [ImageLoader()], paths: ['test/assets/fire.png']);

    final updates = <double>[];
    request.addListener(() => updates.add(request.value.progress));
    await request;

    expect(updates, isNotEmpty);
    expect(updates.last, 1);
  });

  test('surfaces a one-off failure exactly once', () async {
    // JSON fed to the image loader, so decoding blows up.
    final request = Preload.run(loaders: [ImageLoader()], paths: ['test/assets/data.json']);
    await expectLater(request, throwsA(isA<Exception>()));
  });

  test('records what a load failed with', () async {
    final preload = Preload();
    preload.register(ImageLoader());
    final request = preload.load(paths: ['test/assets/data.json']);
    await expectLater(request, throwsA(isA<Exception>()));

    expect(request.value.done, isTrue);
    expect(request.value.error, isA<Exception>());
    expect(request.value.stackTrace, isNotNull);
    request.dispose();
  });

  test('disposing a running request cancels it', () async {
    final loader = TestLoader()..gates['a.png'] = Completer<void>();
    final preload = Preload(concurrency: 1);
    preload.register(loader);
    final request = preload.load(paths: ['a.png', 'b.png']);

    // Two turns let the pool hand `a.png` to the loader; `b.png` stays queued.
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final snapshots = <PreloadSnapshot>[];
    request.addListener(() => snapshots.add(request.value));
    request.dispose();

    expect(snapshots, hasLength(1));
    expect(snapshots.single.done, isTrue);
    expect(snapshots.single.cancelled, isTrue);

    final result = await request;
    expect(result.cancelled, isTrue);

    loader.gates['a.png']!.complete();

    for (var i = 0; i < 10; i += 1) {
      await Future<void>.delayed(Duration.zero);
    }

    expect(loader.loaded, ['a.png'], reason: 'the queued asset must never start');
    expect(Ignis.cache.contains('a.png'), isTrue, reason: 'the in-flight asset still lands');
    await preload.dispose();
  });

  test('disposing a finished request notifies nothing further', () async {
    final preload = Preload();
    preload.register(ImageLoader());
    final request = preload.load(paths: ['test/assets/fire.png']);
    final snapshot = await request;
    expect(snapshot.succeeded, isTrue);

    var notifies = 0;
    request.addListener(() => notifies += 1);
    request.dispose();

    expect(notifies, 0);
  });

  test('rejects loading once disposed', () async {
    final preload = Preload();
    preload.register(ImageLoader());
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
    preload.register(NoopLoader());
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
