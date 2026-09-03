import 'package:ignis/ignis.dart';

/// A server that registers nodes.
final class TestServer extends Server {
  final nodes = <Node>[];

  Cleanup add(Node node) {
    nodes.add(node);
    return scope(() => nodes.remove(node));
  }
}
