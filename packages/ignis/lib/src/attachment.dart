part of 'core.dart';

sealed class _Attachment {
  const _Attachment();

  Node? get parent => null;

  Node? get destination => null;

  Task? get task => null;
}

final class _Detached extends _Attachment {
  const _Detached();
}

final class _Attached extends _Attachment {
  @override
  final Node parent;

  const _Attached(this.parent);

  @override
  Node get destination => parent;
}

final class _Arriving extends _Attachment {
  @override
  final Node destination;

  @override
  final Task task;

  const _Arriving(this.destination, this.task);
}

final class _Moving extends _Attachment {
  @override
  final Node parent;

  @override
  final Node destination;

  @override
  final Task task;

  const _Moving(this.parent, this.destination, this.task);
}

final class _Removing extends _Attachment {
  @override
  final Node parent;

  @override
  final Task task;

  const _Removing(this.parent, this.task);
}
