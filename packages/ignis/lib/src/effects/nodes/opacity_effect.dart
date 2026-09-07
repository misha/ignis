import 'package:ignis/src/core.dart';
import 'package:ignis/src/effects/nodes/timeline_effect.dart';
import 'package:ignis/src/owners/opacity_owner.dart';
import 'package:ignis/src/timeline.dart';

/// An effect that animates an [OpacityOwner]'s opacity over time, fading its
/// whole subtree as one image.
abstract class OpacityEffect extends TimelineEffect {
  late final Target<OpacityOwner> _target;

  /// The [OpacityOwner] whose opacity is mutated by this effect.
  OpacityOwner get target => _target.value;

  /// Fades the closest [OpacityOwner] ancestor in, from nothing to whole.
  factory OpacityEffect.fadeIn({
    required Timeline timeline,
    bool? cleanup,
    bool? enabled,
  }) = _FadeInEffect;

  /// Fades the closest [OpacityOwner] ancestor out, from whole to nothing.
  factory OpacityEffect.fadeOut({
    required Timeline timeline,
    bool? cleanup,
    bool? enabled,
  }) = _FadeOutEffect;

  OpacityEffect._({
    required super.timeline,
    super.cleanup,
    super.enabled,
  }) {
    _target = Target<OpacityOwner>(this);
  }
}

class _FadeInEffect extends OpacityEffect {
  _FadeInEffect({
    required super.timeline,
    super.cleanup,
    super.enabled,
  }) : super._();

  @override
  void build() {
    super.build();

    onProgress((progress) {
      target.opacity = progress;
    });
  }
}

class _FadeOutEffect extends OpacityEffect {
  _FadeOutEffect({
    required super.timeline,
    super.cleanup,
    super.enabled,
  }) : super._();

  @override
  void build() {
    super.build();

    onProgress((progress) {
      target.opacity = 1 - progress;
    });
  }
}
