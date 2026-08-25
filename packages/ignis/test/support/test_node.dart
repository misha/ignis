import 'package:ignis/ignis.dart';

final class TestLog {
  final mounts = <String>[];
  final unmounts = <String>[];
  final updates = <String>[];
  final renders = <String>[];
  final builds = <String>[];
}

class TestNode extends Node {
  final String name;
  TestLog? log;
  int mounts = 0;
  int unmounts = 0;
  double elapsed = 0;
  int updates = 0;
  int renders = 0;
  int builds = 0;
  void Function()? action;
  void Function(TestNode node)? builder;

  TestNode({
    this.name = 'test',
    this.log,
    this.builder,
    super.enabled,
    super.priority,
    super.children,
  }) {
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
  void build() {
    super.build();
    tick((dt) {
      elapsed += dt;
      updates += 1;
      log?.updates.add(name);
      action?.call();
    });

    draw((canvas) {
      renders += 1;
      log?.renders.add(name);
    });

    builds += 1;
    log?.builds.add(name);
    builder?.call(this);
  }
}

final class LiveTestNode extends TestNode with Live {
  LiveTestNode({
    super.name,
    super.log,
    void Function(LiveTestNode node)? builder,
    super.enabled,
    super.priority,
    super.children,
  }) : super(
         builder: builder == null
             ? null //
             : (node) => builder(node as LiveTestNode),
       );
}
