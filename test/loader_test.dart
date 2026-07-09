import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import 'support/test_bundle.dart';

class _RecordingLoader extends Loader {
  final List<String> loaded = [];
  final void Function()? onLoad;

  _RecordingLoader({this.onLoad});

  @override
  void load(LoadingContext context) {
    loaded.add(context.asset);
    onLoad?.call();
  }
}

void main() {
  final bundle = TestBundle([]);

  LoadingContext contextFor(String asset) {
    return LoadingContext(cache: Cache(), bundle: bundle, asset: asset);
  }

  test('passes the context to every loader', () async {
    final a = _RecordingLoader();
    final b = _RecordingLoader();
    final loader = Loader.multiple([a, b]);

    await loader.run(contextFor('test/assets/fire.png'));

    expect(a.loaded, ['test/assets/fire.png']);
    expect(b.loaded, ['test/assets/fire.png']);
  });

  test('runs loaders in list order', () async {
    final order = <String>[];

    final a = _RecordingLoader(onLoad: () => order.add('a'));
    final b = _RecordingLoader(onLoad: () => order.add('b'));

    await Loader.multiple([a, b]).run(contextFor('test/assets/fire.png'));

    expect(order, ['a', 'b']);
  });

  test('respects each loader\'s own filters', () async {
    final a = _RecordingLoader()..extensions(['png']);
    final b = _RecordingLoader()..extensions(['json']);

    await Loader.multiple([a, b]).run(contextFor('test/assets/fire.png'));

    expect(a.loaded, ['test/assets/fire.png']);
    expect(b.loaded, isEmpty);
  });

  test('is itself filterable as a single loader', () async {
    final a = _RecordingLoader();
    final loader = Loader.multiple([a])..extensions(['json']);

    await loader.run(contextFor('test/assets/fire.png'));

    expect(a.loaded, isEmpty);
  });
}
