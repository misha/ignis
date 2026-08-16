import 'package:ignis/ignis.dart';

final class TestLog {
  final mounts = <String>[];
  final unmounts = <String>[];
  final updates = <String>[];
  final renders = <String>[];
  final reassembles = <String>[];
}

final class TestNode extends Node {
  final String name;
  TestLog? log;
  int mounts = 0;
  int unmounts = 0;
  double elapsed = 0;
  int updates = 0;
  int renders = 0;
  int reassembles = 0;
  void Function()? action;

  TestNode([this.name = 'test', this.log]) {
    onMount(() {
      mounts += 1;
      log?.mounts.add(name);
    });

    onUnmount(() {
      unmounts += 1;
      log?.unmounts.add(name);
    });
  }

  @override
  void tick(double dt) {
    elapsed += dt;
    updates += 1;
    log?.updates.add(name);
    action?.call();
  }

  @override
  void render(Canvas canvas) {
    renders += 1;
    log?.renders.add(name);
    super.render(canvas);
  }

  @override
  void reassemble() {
    reassembles += 1;
    log?.reassembles.add(name);
    action?.call();
    super.reassemble();
  }
}
