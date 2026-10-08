import 'package:ignis/ignis.dart';

/// A node that records every non-system [Message] it processes, such as those
/// its children post to it.
final class TestSink extends Node {
  final received = <Message>[];

  TestSink([Iterable<Node> children = const []]) : super(children: children);

  /// The recorded messages of type [T], in the order they arrived.
  List<T> of<T extends Message>() => received.whereType<T>().toList();

  @override
  void process(Message message) {
    super.process(message);
    if (message is SystemMessage) return;
    received.add(message);
  }
}
