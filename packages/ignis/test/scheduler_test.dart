import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/src/scheduler.dart';

void main() {
  test('flush executes tasks in the order they were scheduled', () {
    final log = <String>[];
    final scheduler = Scheduler()
      ..schedule(Task(() => log.add('a')))
      ..schedule(Task(() => log.add('b')))
      ..schedule(Task(() => log.add('c')));

    scheduler.flush();

    expect(log, ['a', 'b', 'c']);
  });

  test('a task scheduled during a flush executes in the same flush', () {
    final log = <String>[];
    final scheduler = Scheduler();
    final later = Task(() => log.add('b'));

    scheduler
      ..schedule(
        Task(() {
          log.add('a');
          scheduler.schedule(later);
        }),
      )
      ..flush();

    expect(log, ['a', 'b']);
  });

  test('a task executed by one flush can be scheduled for the next', () {
    final log = <String>[];
    final task = Task(() => log.add('a'));
    final scheduler = Scheduler();

    scheduler
      ..schedule(task)
      ..flush()
      ..schedule(task)
      ..flush();

    expect(log, ['a', 'a']);
  });

  test('a task run without a scheduler executes at once', () {
    final log = <String>[];

    Task(() => log.add('a')).run(null);

    expect(log, ['a']);
  });

  test('a task run with a scheduler executes at its flush', () {
    final log = <String>[];
    final scheduler = Scheduler();

    Task(() => log.add('a')).run(scheduler);
    expect(log, isEmpty);

    scheduler.flush();
    expect(log, ['a']);
  });
}
