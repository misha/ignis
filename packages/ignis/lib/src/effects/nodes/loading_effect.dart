// SPDX-AI-Disclosure: none

import 'package:flutter/foundation.dart';
import 'package:ignis/src/assets/preload.dart';
import 'package:ignis/src/core.dart';
import 'package:ignis/src/nodes/effect_node.dart';

/// An effect that finishes once its preload [request] lands successfully.
///
/// A failed load emits [onError] and disables this effect instead, so
/// anything gated on [onFinish] stays gated. Recover through [onError].
/// A cancelled request disables this effect quietly.
class LoadingEffect extends EffectNode {
  /// The load this effect tracks.
  final PreloadRequest request;

  bool _reported = false;

  /// How far along the load is, 0 to 1.
  double get progress => request.value.progress;

  /// Whether the load has landed successfully.
  bool get isFinished => _reported && request.value.succeeded;

  /// Emitted once if the load fails, with the snapshot carrying the failure.
  final onError = Signal1<PreloadSnapshot>();

  LoadingEffect({
    required this.request,
    super.cleanup,
    super.enabled,
    super.priority,
  });

  @override
  void build() {
    super.build();

    tick((dt) {
      final snapshot = request.value;
      if (_reported || !snapshot.done) return;
      _reported = true;

      if (snapshot.cancelled) {
        // TODO: Not sure disabling the effect is the right thing to do.
        //  Realistically, what are you supposed to do if it fails?
        //  Detatching the node might be the more intuitive response.
        disable();
        return;
      }

      if (snapshot.hasError) {
        disable();

        FlutterError.reportError(
          FlutterErrorDetails(
            exception: snapshot.error!,
            stack: snapshot.stackTrace,
            library: 'ignis',
            context: ErrorDescription('while preloading'),
          ),
        );

        onError.emit(snapshot);
        return;
      }

      onFinish.emit();
    });
  }

  @override
  void reset() {
    _reported = false;
  }
}
