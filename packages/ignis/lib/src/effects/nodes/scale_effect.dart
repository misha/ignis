// SPDX-AI-Disclosure: none

import 'package:ignis/src/core.dart';
import 'package:ignis/src/effects/interfaces/measurable_effect.dart';
import 'package:ignis/src/effects/nodes/timeline_effect.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/owners/scale_owner.dart';
import 'package:ignis/src/timeline.dart';

/// An effect that animates a [ScaleOwner]'s scale over time.
abstract class ScaleEffect extends TimelineEffect implements MeasurableEffect {
  late final Target<ScaleOwner> _target;

  /// The [ScaleOwner] whose scale is mutated by this effect.
  ScaleOwner get target => _target.value;

  /// Scales the closest [ScaleOwner] ancestor by [offset], relative to its
  /// scale when the effect starts.
  factory ScaleEffect.by({
    required Vector2 offset,
    required Timeline timeline,
    bool? cleanup,
    bool? enabled,
  }) = _ScaleByEffect;

  /// Scales the closest [ScaleOwner] ancestor to [destination].
  factory ScaleEffect.to({
    required Vector2 destination,
    required Timeline timeline,
    bool? cleanup,
    bool? enabled,
  }) = _ScaleToEffect;

  ScaleEffect._({
    required super.timeline,
    super.cleanup,
    super.enabled,
  }) {
    _target = Target<ScaleOwner>(this);
  }
}

class _ScaleByEffect extends ScaleEffect {
  final Vector2 _offset;

  _ScaleByEffect({
    required Vector2 offset,
    required super.timeline,
    super.cleanup,
    super.enabled,
  }) : _offset = offset.clone(),
       super._();

  @override
  void build() {
    super.build();

    onProgress((progress) {
      target.scale.addScaled(_offset, progress - previousProgress);
    });
  }

  @override
  double measure() => _offset.length;
}

class _ScaleToEffect extends ScaleEffect {
  final Vector2 _destination;
  final MVector2 _offset = .zero();

  _ScaleToEffect({
    required Vector2 destination,
    required super.timeline,
    super.cleanup,
    super.enabled,
  }) : _destination = destination.clone(),
       super._();

  @override
  void build() {
    super.build();

    _offset
      ..setFrom(_destination)
      ..subtract(target.scale);

    onProgress((progress) {
      target.scale.addScaled(_offset, progress - previousProgress);
    });
  }

  @override
  double measure() => _offset.length;
}
