import 'dart:ui';

import 'package:ignis/src/globals.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/sprite.dart';
import 'package:ignis/src/sprites/sprite_entry.dart';
import 'package:ignis/src/sprites/sprite_key.dart';

/// One image, drawn whole.
///
/// ```dart
/// final logo = SpriteImage('assets/logo.png');
/// ```
class SpriteImage<T> extends Sprite<T> {
  /// The cache key this was drawn from.
  final String asset;

  /// What its one entry answers to, or null to go unnamed.
  final T? id;

  final Image _image;
  final Vector2 _size;
  final Rect _rect;

  /// Draws the image cached at [asset] whole.
  factory SpriteImage(String asset, {T? id}) {
    return SpriteImage._(Ignis.cache.retrieve<Image>(asset), asset, id);
  }

  SpriteImage._(this._image, this.asset, this.id) //
    : _size = .cast(_image.width, _image.height),
      _rect = .fromLTWH(0, 0, _image.width.toDouble(), _image.height.toDouble());

  @override
  int get length => 1;

  @override
  Image image(_) => _image;

  @override
  Vector2 size(_) => _size;

  @override
  int frames(_) => 1;

  @override
  Rect rect(_, _) => _rect;

  @override
  double duration(_, _) => double.infinity;

  @override
  bool loops(_) => false;

  @override
  SpriteEntry<T>? resolve(SpriteKey<T> key) {
    switch (key) {
      case SpriteIndex():
        return SpriteEntry(0, id);

      case SpriteId(:final id) when this.id == id:
        return SpriteEntry(0, id);

      default:
        return null;
    }
  }

  @override
  SpriteImage<T> reload() {
    final image = Ignis.cache.retrieve<Image>(asset);
    if (identical(image, _image)) return this;
    return SpriteImage._(image, asset, id);
  }
}
