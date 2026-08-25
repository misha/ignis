import 'dart:io';

import 'package:flutter/services.dart';

/// An asset bundle backed by files on disk, listing [assets] in a synthetic
/// `AssetManifest.bin`.
///
/// The package declares no Flutter assets, so there is no compiled bundle to
/// read from: a load resolves the key as a path, relative to the package root.
class TestBundle extends AssetBundle {
  /// The assets the synthetic manifest lists.
  final List<String> assets;

  TestBundle([this.assets = const []]);

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      final manifest = {
        for (final asset in assets) //
          asset: [
            {
              'asset': asset,
            },
          ],
      };

      return const StandardMessageCodec().encodeMessage(manifest)!;
    }

    final bytes = await File(key).readAsBytes();
    return ByteData.sublistView(bytes);
  }
}
