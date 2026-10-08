import 'package:ignis/ignis.dart';

import 'test_entity.dart';

/// A component that records what it processes and renders into [log].
class TestComponent extends Component {
  final String name;
  TestLog? log;
  int builds = 0;
  int destroys = 0;
  int updates = 0;
  int renders = 0;

  TestComponent({
    this.name = 'test',
    this.log,
    super.enabled,
    super.priority,
  });

  @override
  void process(Message message) {
    super.process(message);

    switch (message) {
      case Build():
        builds += 1;
        log?.builds.add(name);

      case Destroy():
        destroys += 1;
        log?.unmounts.add(name);

      case Update():
        updates += 1;
        log?.updates.add(name);
    }
  }

  @override
  void render(Canvas canvas) {
    renders += 1;
    log?.renders.add(name);
  }
}
