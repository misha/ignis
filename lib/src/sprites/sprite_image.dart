import 'package:ignis/src/sprite.dart';
import 'package:ignis/src/sprites/sprite_entry.dart';
import 'package:ignis/src/sprites/sprite_region.dart';

/// One region, drawn still.
///
/// ```dart
/// final logo = SpriteImage('assets/logo.png');
/// ```
///
/// [SpriteSheet.image] draws one frame of a grid this way, which is how a tile
/// map uses a sheet.
class SpriteImage extends Sprite<int> {
  /// Which piece of which asset this draws.
  final SpriteRegion region;

  @override
  final List<SpriteEntry<int>> entries;

  /// Draws the whole of the image cached at [asset].
  factory SpriteImage(String asset) => .of(SpriteRegion.whole(asset));

  /// Draws [region], which holds one frame.
  SpriteImage.of(this.region)
    : assert(region.frames == 1, 'An image draws one frame.'),
      entries = [
        SpriteEntry(
          index: 0,
          key: 0,
          image: region.image,
          size: region.cell,
          loops: false,
          rects: region.cut(),
          durations: const [double.infinity],
        ),
      ];

  /// The cache key this was drawn from.
  String get asset => region.asset;

  @override
  SpriteEntry<int>? resolve(int key) {
    if (key != 0) return null;
    return entries.single;
  }

  @override
  SpriteImage reload() {
    if (identical(region.image, entries.single.image)) return this;

    // Art replaced by something this region no longer sits inside keeps the
    // frame it last cut, rather than drawing outside the image.
    // TODO: Consider if this is intuitive or not after a few games.
    if (!region.fits) return this;

    return SpriteImage.of(region);
  }
}
