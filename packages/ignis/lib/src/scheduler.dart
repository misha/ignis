// SPDX-AI-Disclosure: none

import 'dart:collection';

import 'package:flutter/foundation.dart';

@internal
abstract base class Ticket extends LinkedListEntry<Ticket> {
  void redeem();

  void cancel() {
    if (list == null) return;
    unlink();
  }
}

@internal
sealed class Scheduler {
  const Scheduler();

  static Scheduler select(Scheduler? a, [Scheduler? b]) {
    return switch ((a, b)) {
      (final QueuedScheduler a, _) => a,
      (_, final QueuedScheduler b) => b,
      _ => const ImmediateScheduler(),
    };
  }

  T? submit<T extends Ticket>(T ticket);

  void flush();
}

@internal
final class ImmediateScheduler extends Scheduler {
  const ImmediateScheduler();

  @override
  T? submit<T extends Ticket>(T ticket) {
    ticket.redeem();
    return null;
  }

  @override
  void flush() {
    // Nothing to do.
  }
}

@internal
final class QueuedScheduler extends Scheduler {
  final _tickets = LinkedList<Ticket>();

  @override
  T? submit<T extends Ticket>(T ticket) {
    _tickets.add(ticket);
    return ticket;
  }

  @override
  void flush() {
    while (_tickets.isNotEmpty) {
      final ticket = _tickets.first..unlink();
      ticket.redeem();
    }
  }
}
