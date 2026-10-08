import 'package:ignis/ignis.dart';

/// An entity that records every non-system [Message] it processes, such as
/// those its components post to it.
final class TestSink extends Entity {
  final received = <Message>[];

  TestSink([Iterable<Component> components = const []]) : super(components: components);

  /// The recorded messages of type [T], in the order they arrived.
  List<T> of<T extends Message>() => received.whereType<T>().toList();

  @override
  void process(Message message) {
    super.process(message);
    if (message is SystemMessage) return;
    received.add(message);
  }
}
