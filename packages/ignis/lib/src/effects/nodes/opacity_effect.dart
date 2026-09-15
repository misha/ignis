import 'package:ignis/src/core.dart';
import 'package:ignis/src/effects/nodes/timeline_effect.dart';
import 'package:ignis/src/owners/opacity_owner.dart';
import 'package:ignis/src/timeline.dart';

/// Animates an [OpacityOwner]'s opacity, fading its whole subtree as one image.
abstract class OpacityEffect extends TimelineEffect {
  late final Target<OpacityOwner> _target;

  /// The [OpacityOwner] this effect drives.
  OpacityOwner get target => _target.value;

  /// Fades the closest [OpacityOwner] ancestor from 0 to 1.
  factory OpacityEffect.fadeIn({
    required Timeline timeline,
    bool? cleanup,
    bool? enabled,
  }) = _FadeInEffect;

  /// Fades the closest [OpacityOwner] ancestor from 1 to 0.
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
