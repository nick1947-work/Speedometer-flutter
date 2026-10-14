import 'package:flutter_test/flutter_test.dart';
import 'package:gps_speedometer/core/constants/speed_units.dart';
import 'package:gps_speedometer/core/utils/kalman_filter.dart';

void main() {
  group('SpeedUnit Conversion Tests', () {
    test('KM/H to MPH conversion', () {
      const kmh = 100.0;
      final mph = SpeedUnit.mph.fromKmh(kmh);
      expect(mph, closeTo(62.13, 0.05));
    });

    test('KM/H to Knots conversion', () {
      const kmh = 100.0;
      final knots = SpeedUnit.knot.fromKmh(kmh);
      expect(knots, closeTo(53.99, 0.05));
    });

    test('Format distance correctly', () {
      expect(SpeedUnit.kmh.formatDistance(1500), '1.50');
      expect(SpeedUnit.mph.formatDistance(1609.344), '1.00');
    });
  });

  group('SpeedKalmanFilter Tests', () {
    test('Stationary deadband snaps to 0', () {
      final filter = SpeedKalmanFilter();
      final speed = filter.update(1.2);
      expect(speed, 0.0);
    });

    test('Moving speed smoothly updates', () {
      final filter = SpeedKalmanFilter();
      var speed = filter.update(60.0);
      expect(speed, greaterThan(0.0));
      expect(speed, lessThanOrEqualTo(60.0));
    });
  });
}
