import 'package:flutter/services.dart';

/// A fake asset bundle that serves a synthetic `AssetManifest.bin` listing
/// [assets], delegating every other load to [rootBundle].
class TestBundle extends AssetBundle {
  final List<String> assets;

  TestBundle(this.assets);

  @override
  Future<ByteData> load(String key) async {
    switch (key) {
      case 'AssetManifest.bin':
        final manifest = {
          for (final asset in assets) //
            asset: [
              {
                'asset': asset,
              },
            ],
        };

        return const StandardMessageCodec().encodeMessage(manifest)!;

      default:
        return rootBundle.load(key);
    }
  }
}
