import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import 'support/test_bundle.dart';

class _RecordingLoader extends Loader {
  final List<String> loaded = [];

  @override
  void load(LoadingContext context) {
    loaded.add(context.asset);
  }
}

void main() {
  // JsonLoader reads through the bundle, which needs a binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  final bundle = TestBundle([]);

  LoadingContext contextFor(String asset) {
    return LoadingContext(cache: Cache(), bundle: bundle, asset: asset);
  }

  test('loads anything when unfiltered', () async {
    final loader = _RecordingLoader();

    await loader.run(contextFor('test/assets/fire.png'));
    await loader.run(contextFor('test/assets/data.json'));

    expect(loader.loaded, ['test/assets/fire.png', 'test/assets/data.json']);
  });

  test('skips assets an extension filter rejects', () async {
    final loader = _RecordingLoader()..extensions(['png']);

    await loader.run(contextFor('test/assets/fire.png'));
    await loader.run(contextFor('test/assets/data.json'));

    expect(loader.loaded, ['test/assets/fire.png']);
  });

  test('accepts any of the listed extensions', () async {
    final loader = _RecordingLoader()..extensions(['png', 'gif']);

    await loader.run(contextFor('test/assets/fire.png'));
    await loader.run(contextFor('test/assets/fire.gif'));

    expect(loader.loaded, ['test/assets/fire.png', 'test/assets/fire.gif']);
  });

  test('skips assets a prefix filter rejects', () async {
    final loader = _RecordingLoader()..prefix('test/assets/');

    await loader.run(contextFor('test/assets/fire.png'));
    await loader.run(contextFor('other/fire.png'));

    expect(loader.loaded, ['test/assets/fire.png']);
  });

  test('requires every filter to pass', () async {
    final loader = _RecordingLoader()
      ..prefix('test/')
      ..extensions(['png']);

    await loader.run(contextFor('test/assets/fire.png'));
    await loader.run(contextFor('test/assets/data.json'));
    await loader.run(contextFor('other/fire.png'));

    expect(loader.loaded, ['test/assets/fire.png']);
  });

  test('decodes JSON into the cache', () async {
    final cache = Cache();

    await JsonLoader().run(
      LoadingContext(
        cache: cache,
        bundle: bundle,
        asset: 'test/assets/data.json',
      ),
    );

    expect(cache.retrieve('test/assets/data.json'), {'hello': 'world'});
  });

  test('does nothing at all when noop', () async {
    final cache = Cache();

    await Loader.noop().run(
      LoadingContext(
        cache: cache,
        bundle: bundle,
        asset: 'test/assets/fire.png',
      ),
    );

    expect(cache.length, 0);
  });
}
