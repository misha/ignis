import 'package:flutter/rendering.dart' show FlexFit;
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('none asks for no share, and fits loosely', () {
    expect((LayoutFlex.none.factor, LayoutFlex.none.fit), (0, FlexFit.loose));
  });

  test('expanded takes a share of the leftover space and fills it', () {
    const flex = LayoutFlex.expanded(2);
    expect((flex.factor, flex.fit), (2, FlexFit.tight));
  });

  test('flexible takes a share of the leftover space without filling it', () {
    const flex = LayoutFlex.flexible(3);
    expect((flex.factor, flex.fit), (3, FlexFit.loose));
  });

  test('both default to a single share', () {
    expect(LayoutFlex.expanded().factor, 1);
    expect(LayoutFlex.flexible().factor, 1);
  });

  test('rejects a factor that asks for no space', () {
    expect(() => LayoutFlex.expanded(0), throwsAssertionError);
    expect(() => LayoutFlex.flexible(-1), throwsAssertionError);
  });

  test('a node defaults to no flex', () {
    expect(BoxNode().flex, LayoutFlex.none);
  });

  group('equality', () {
    test('the same factor and fit are equal, and hash alike', () {
      expect(LayoutFlex.expanded(2), LayoutFlex.expanded(2));
      expect(LayoutFlex.expanded(2).hashCode, LayoutFlex.expanded(2).hashCode);
    });

    test('a different factor is not equal', () {
      expect(LayoutFlex.expanded(2), isNot(LayoutFlex.expanded(3)));
    });

    test('the same factor with a different fit is not equal', () {
      expect(LayoutFlex.expanded(2), isNot(LayoutFlex.flexible(2)));
    });
  });

  test('toString names the factor and the fit', () {
    expect(LayoutFlex.expanded(2).toString(), 'LayoutFlex(2, FlexFit.tight)');
  });
}
