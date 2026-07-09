import 'dart:developer';
import 'dart:isolate' as isolate;

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

/// Runs [benchmark] under the Dart VM's CPU sampling profiler and prints a
/// self-time breakdown by function, instead of just a timing score.
///
/// Requires the VM service, so the file must be run with `--enable-vmservice`.
Future<void> profile(
  AsyncBenchmarkBase benchmark, {
  int warmupReps = 3,
  int reps = 20,
  int top = 40,
}) async {
  final info = await Service.getInfo();
  final uri = info.serverUri!;
  final wsUri = 'ws://${uri.authority}${uri.path}ws';
  final service = await vmServiceConnectUri(wsUri);
  final isolateId = Service.getIsolateId(isolate.Isolate.current)!;
  await service.setFlag('profile_period', '250');
  await benchmark.setup();

  // Warm up the JIT.
  for (var i = 0; i < warmupReps; i += 1) {
    await benchmark.run();
  }

  await service.clearCpuSamples(isolateId);
  final startTimestamp = await service.getVMTimelineMicros();

  for (var i = 0; i < reps; i += 1) {
    await benchmark.run();
  }

  final endTimestamp = await service.getVMTimelineMicros();
  await benchmark.teardown();

  final from = startTimestamp.timestamp!;
  final to = endTimestamp.timestamp!;
  final duration = to - from;
  final samples = await service.getCpuSamples(isolateId, from, duration);
  final count = samples.sampleCount ?? 0;
  if (count == 0) throw StateError('No samples recorded.');

  final entries = <({ProfileFunction function, int exclusive, int inclusive})>[
    for (final function in samples.functions!) //
      (
        function: function,
        exclusive: function.exclusiveTicks ?? 0,
        inclusive: function.inclusiveTicks ?? 0,
      ),
  ];

  entries.sort((a, b) => b.exclusive.compareTo(a.exclusive));

  final buffer = StringBuffer();

  buffer.writeln(
    '=== '
    '${benchmark.name}: '
    '$count samples '
    'over $duration us '
    '($reps reps) '
    '===',
  );

  for (final (:function, :exclusive, :inclusive) in entries.take(top)) {
    if (exclusive == 0) continue;
    final usage = exclusive / count * 100;

    buffer.writeln(
      '${usage.toStringAsFixed(2).padLeft(6)}%  '
      'excl=$exclusive  '
      'incl=$inclusive  '
      '${_describe(function)}',
    );
  }

  print(buffer.toString());
  await service.dispose();
}

/// Generates a useful (?) name for the given profiling function.
String _describe(ProfileFunction function) {
  final target = function.function;

  try {
    final name = switch (target) {
      FuncRef(:final name) => name,
      _ => target.toString(),
    };

    final owner = switch (target.owner) {
      ClassRef(:final name) => name,
      LibraryRef(:final uri) => uri,
      _ => null,
    };

    if (owner != null) {
      return '$owner.$name';
    } else {
      return '$name';
    }
  } catch (_) {
    return target.toString();
  }
}
