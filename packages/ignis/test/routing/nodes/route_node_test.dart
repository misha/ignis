import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('a route not directly under a router node throws', () {
    expect(() => RouteNode(name: 'a').mount(), throwsA(isA<StateError>()));

    final host = RouterNode(
      router: Router<String>(),
      children: [
        Node(
          children: [
            RouteNode(name: 'a'),
          ],
        ),
      ],
    );

    expect(() => host.mount(), throwsA(isA<StateError>()));
  });

  test('a lax route mounts anywhere and takes no part', () {
    final route = RouteNode(name: 'a', strict: false);

    expect(() => route.mount(), returnsNormally);
  });
}
