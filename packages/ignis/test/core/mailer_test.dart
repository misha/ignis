import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  late List<String> log;
  late _TestMailer mailer;

  setUp(() {
    log = [];
    mailer = _TestMailer();
  });

  test('mails every subscriber in subscription order', () {
    mailer
      ..subscribe(_Inbox('b', log))
      ..subscribe(_Inbox('a', log))
      ..send();

    expect(log, ['b', 'a']);
  });

  test('ignores a duplicate subscription', () {
    final inbox = _Inbox('a', log);

    mailer
      ..subscribe(inbox)
      ..subscribe(inbox)
      ..send();

    expect(log, ['a']);
  });

  test('stops mailing an unsubscribed address', () {
    final inbox = _Inbox('a', log);

    mailer
      ..subscribe(inbox)
      ..unsubscribe(inbox)
      ..send();

    expect(log, isEmpty);
  });

  test('applies changes made during a mail from the next one', () {
    final a = _Inbox('a', log);
    final b = _Inbox('b', log);
    final c = _Inbox('c', log);

    a.action = () {
      mailer
        ..unsubscribe(b)
        ..subscribe(c);
    };

    mailer
      ..subscribe(a)
      ..subscribe(b)
      ..send();

    expect(log, ['a', 'b']);

    log.clear();
    a.action = null;
    mailer.send();

    expect(log, ['a', 'c']);
  });
}

final class _TestMailer with Mailer {
  void send() => mail(const _Ping());
}

final class _Ping extends Message {
  const _Ping();
}

/// Records its [name] in [log] for every message posted to it.
final class _Inbox with Address {
  final String name;
  final List<String> log;

  /// Runs after each post is recorded.
  void Function()? action;

  _Inbox(this.name, this.log);

  @override
  void post(Message message) {
    log.add(name);
    action?.call();
  }
}
