import 'package:ignis/ignis.dart';

final class TestLog {
  final mounts = <String>[];
  final unmounts = <String>[];
  final updates = <String>[];
  final renders = <String>[];
  final builds = <String>[];
}

class TestEntity extends Entity {
  final String name;
  TestLog? log;
  int mounts = 0;
  int unmounts = 0;
  double elapsed = 0;
  int updates = 0;
  int renders = 0;
  int builds = 0;
  void Function()? action;
  void Function(TestEntity entity)? builder;
  void Function(TestEntity entity, Message message)? processor;

  TestEntity({
    this.name = 'test',
    this.log,
    this.builder,
    this.processor,
    super.enabled,
    super.priority,
    super.components,
    super.children,
  });

  @override
  void process(Message message) {
    super.process(message);

    switch (message) {
      case Build():
        mounts += 1;
        log?.mounts.add(name);

        builds += 1;
        log?.builds.add(name);
        builder?.call(this);

      case Destroy():
        unmounts += 1;
        log?.unmounts.add(name);
    }

    switch (message) {
      case Update(:final dt):
        elapsed += dt;
        updates += 1;
        log?.updates.add(name);
        action?.call();
    }

    processor?.call(this, message);
  }

  @override
  void render(Canvas canvas) {
    renders += 1;
    log?.renders.add(name);
    super.render(canvas);
  }
}
