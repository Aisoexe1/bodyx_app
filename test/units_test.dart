import 'package:flutter_test/flutter_test.dart';

import 'package:bodyx_app/logic/units.dart';

void main() {
  group('unit conversions', () {
    test('cm/inches round-trip', () {
      expect(cmToInches(190), closeTo(74.8, 0.1));
      expect(inchesToCm(cmToInches(190)), closeTo(190, 0.001));
    });

    test('kg/lb round-trip', () {
      expect(kgToLb(75), closeTo(165.3, 0.1));
      expect(lbToKg(kgToLb(75)), closeTo(75, 0.001));
    });
  });
}
