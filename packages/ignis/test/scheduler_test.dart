import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/src/scheduler.dart';

void main() {
  test('flush executes tasks in the order they were scheduled', () {
    final log = <String>[];
    final scheduler = Scheduler()
      ..schedule(_Entry('a', log))
      ..schedule(_Entry('b', log))
      ..schedule(_Entry('c', log));

    scheduler.flush();

    expect(log, ['a', 'b', 'c']);
  });

  test('flush executes only the tasks still scheduled', () {
    final log = <String>[];
    final cancelled = _Entry('b', log);
    final scheduler = Scheduler()
      ..schedule(_Entry('a', log))
      ..schedule(cancelled)
      ..schedule(_Entry('c', log));

    cancelled.cancel();
    scheduler.flush();

    expect(log, ['a', 'c']);
  });

  test('a cancelled task can be scheduled again', () {
    final log = <String>[];
    final task = _Entry('a', log);
    final scheduler = Scheduler();

    scheduler.schedule(task);
    task.cancel();
    scheduler.schedule(task);
    scheduler.flush();

    expect(log, ['a']);
  });

  test('a task scheduled during a flush executes in the same flush', () {
    final log = <String>[];
    final scheduler = Scheduler();
    final later = _Entry('b', log);

    scheduler
      ..schedule(_Entry('a', log, () => scheduler.schedule(later)))
      ..flush();

    expect(log, ['a', 'b']);
  });

  test('a task executed by one flush can be scheduled for the next', () {
    final log = <String>[];
    final task = _Entry('a', log);
    final scheduler = Scheduler();

    scheduler
      ..schedule(task)
      ..flush()
      ..schedule(task)
      ..flush();

    expect(log, ['a', 'a']);
  });
}

final class _Entry extends Task {
  final String name;
  final List<String> log;
  final void Function()? then;

  _Entry(this.name, this.log, [this.then]);

  @override
  void execute() {
    log.add(name);
    then?.call();
  }
}
