import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/src/equality.dart';

void main() {
  const keys = SameValueEquality();

  test('pairs NaN with NaN', () {
    expect(keys.equals(double.nan, double.nan), isTrue);
    expect(keys.hash(double.nan), keys.hash(double.nan));
  });

  test('tells 0.0 and -0.0 apart', () {
    expect(keys.equals(0.0, -0.0), isFalse);
    expect(keys.equals(-0.0, -0.0), isTrue);
  });

  test('compares everything else by ==', () {
    expect(keys.equals('a', 'a'), isTrue);
    expect(keys.equals(1, 2), isFalse);
  });

  test('compares nested collections by content when deepened', () {
    const deep = DeepCollectionEquality(SameValueEquality());

    // dart format off
    expect(deep.equals([[1, double.nan]], [[1, double.nan]]), isTrue);
    expect(deep.equals([{'a': 0.0}], [{'a': -0.0}]), isFalse);
    // dart format on
  });
}
