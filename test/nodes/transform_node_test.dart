import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('distance returns the distance between two nodes\' positions', () {
    final a = TransformNode(position: .new(0, 0));
    final b = TransformNode(position: .new(3, 4));

    expect(a.distance(b), 5);
  });

  test('distance2 returns the squared distance between two nodes\' positions', () {
    final a = TransformNode(position: .new(0, 0));
    final b = TransformNode(position: .new(3, 4));

    expect(a.distance2(b), 25);
  });
}
