import 'package:ignis/ignis.dart';
import 'package:ignis/src/core.dart' show scope;

/// A registry of nodes, standing in for a subsystem a node registers with.
final class TestRegistry {
  final nodes = <Node>[];

  Cleanup add(Node node) {
    nodes.add(node);
    return scope(() => nodes.remove(node));
  }
}
