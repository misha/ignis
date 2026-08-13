import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  group('factories', () {
    test('tight fixes both min and max to size', () {
      final constraints = LayoutConstraints.tight(.new(10, 20));

      expect(constraints.min, Vector2(10, 20));
      expect(constraints.max, Vector2(10, 20));
      expect(constraints.isTight, isTrue);
    });

    test('loose spans zero to size', () {
      final constraints = LayoutConstraints.loose(.new(10, 20));

      expect(constraints.min, Vector2.zero());
      expect(constraints.max, Vector2(10, 20));
    });

    test('unbounded has no minimum and an infinite maximum', () {
      final constraints = LayoutConstraints.unbounded();

      expect(constraints.min, Vector2.zero());
      expect(constraints.max, Vector2(double.infinity, double.infinity));
      expect(constraints.hasBoundedWidth, isFalse);
      expect(constraints.hasBoundedHeight, isFalse);
    });
  });

  group('constrain', () {
    test('clamps a size within min and max', () {
      final constraints = LayoutConstraints(min: .all(10), max: .all(50));

      expect(constraints.satisfy(.new(5, 100)), Vector2(10, 50));
      expect(constraints.satisfy(.all(20)), Vector2(20, 20));
    });

    test('clamps an infinite size down to a finite max', () {
      final constraints = LayoutConstraints(min: .zero(), max: .new(50, 30));
      expect(constraints.satisfy(.all(double.infinity)), Vector2(50, 30));
    });

    test('leaves an infinite max unbounded', () {
      final constraints = LayoutConstraints.unbounded();
      expect(constraints.satisfy(.new(50, 30)), Vector2(50, 30));
    });
  });

  group('biggest and smallest', () {
    test('report max and min respectively', () {
      final constraints = LayoutConstraints(min: .new(10, 20), max: .new(30, 40));

      expect(constraints.biggest, Vector2(30, 40));
      expect(constraints.smallest, Vector2(10, 20));
    });
  });

  group('loosen', () {
    test('clears min to zero, keeping max', () {
      final constraints = LayoutConstraints(min: .new(10, 20), max: .new(30, 40)).loosen();

      expect(constraints.min, Vector2.zero());
      expect(constraints.max, Vector2(30, 40));
    });
  });

  group('deflate', () {
    test('subtracts padding from min and max', () {
      final constraints = LayoutConstraints(min: .all(30), max: .all(100));
      final deflated = constraints.deflate(.all(10));

      expect(deflated.min, Vector2(10, 10));
      expect(deflated.max, Vector2(80, 80));
    });

    test('clamps min to zero when padding exceeds it', () {
      final constraints = LayoutConstraints(min: .all(4), max: .all(100));
      final deflated = constraints.deflate(.all(10));

      expect(deflated.min, Vector2.zero());
    });

    test('collapses to zero when padding exceeds the whole box', () {
      final constraints = LayoutConstraints(min: .zero(), max: .all(5));
      final deflated = constraints.deflate(.all(10));

      expect(deflated.min, Vector2.zero());
      expect(deflated.max, Vector2.zero());
    });
  });

  group('validation', () {
    test('rejects a min greater than max', () {
      expect(() => LayoutConstraints(min: .new(10, 0), max: .new(5, 0)), throwsAssertionError);
    });
  });

  group('equality', () {
    test('constraints with the same min and max are equal', () {
      expect(
        LayoutConstraints(min: .zero(), max: .all(10)),
        LayoutConstraints(min: .zero(), max: .all(10)),
      );
    });

    test('constraints with different min or max are not equal', () {
      expect(
        LayoutConstraints(min: .zero(), max: .all(10)),
        isNot(LayoutConstraints(min: .zero(), max: .new(20, 10))),
      );
    });
  });

  group('defensive copying', () {
    test('mutating the input vectors afterward does not affect the constraints', () {
      final min = Vector2.zero();
      final max = Vector2.all(10);
      final constraints = LayoutConstraints(min: min, max: max);

      min.mutate().setValues(5, 5);
      max.mutate().setValues(20, 20);

      expect(constraints.min, Vector2.zero());
      expect(constraints.max, Vector2.all(10));
    });
  });
}
