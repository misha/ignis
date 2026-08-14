// ignore_for_file: invalid_use_of_internal_member

import 'dart:math';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:ignis/ignis.dart';

import 'runner.dart';

/// Scattered nodes queried with [TransformNode.nearest], [ticks] times over.
class NearestBenchmark extends AsyncBenchmarkBase {
  final int seed;
  final int targets;
  final int groups;
  final int seekers;
  final int ticks;
  final double bounds;

  late Scene<Node> scene;

  final List<_SeekerNode> _seekers = [];

  NearestBenchmark({
    this.seed = 12345,
    this.targets = 1000,
    this.groups = 20,
    this.seekers = 10,
    this.ticks = 10,
    this.bounds = 2000,
  }) : super('Nearest');

  @override
  Future<void> setup() async {
    final random = Random(seed);
    final root = Node();
    final parents = <TransformNode>[];
    final count = groups + targets + seekers;
    final layout = List.generate(count, (i) {
      return Vector2(
        (random.nextDouble() - 0.5) * bounds,
        (random.nextDouble() - 0.5) * bounds,
      );
    });

    for (var i = 0; i < groups; i += 1) {
      final entry = layout[i];
      final parent = TransformNode(position: .new(entry.x, entry.y));
      parents.add(parent);
      root.add(parent);
    }

    for (var i = 0; i < targets; i += 1) {
      final entry = layout[groups + i];
      parents[i % groups].add(_TargetNode(position: .new(entry.x, entry.y)));
    }

    for (var i = 0; i < seekers; i += 1) {
      final entry = layout[groups + targets + i];
      final seeker = _SeekerNode(position: .new(entry.x, entry.y));
      _seekers.add(seeker);
      root.add(seeker);
    }

    scene = root.mount();
  }

  @override
  Future<void> run() async {
    var found = 0;

    for (var t = 0; t < ticks; t += 1) {
      for (final seeker in _seekers) {
        if (seeker.nearest<_TargetNode>() != null) {
          found += 1;
        }
      }
    }

    if (found != ticks * seekers) throw StateError('missing results: $found');
  }

  @override
  Future<void> teardown() async => scene.destroy();
}

class _TargetNode extends TransformNode {
  _TargetNode({
    required super.position,
  });
}

class _SeekerNode extends TransformNode {
  _SeekerNode({
    required super.position,
  });
}

Future<void> main() async {
  await runBenchmark(NearestBenchmark());
}
