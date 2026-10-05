part of 'core.dart';

final class _ReparentTicket extends Ticket {
  final Node node;
  final Node? parent;

  _ReparentTicket(this.node, this.parent);

  @override
  void redeem() {
    node._reparent(parent);
  }
}

final class _ReorderTicket extends Ticket {
  final Node node;
  final int priority;

  _ReorderTicket(this.node, this.priority);

  @override
  void redeem() {
    node._reorder(priority);
  }
}
