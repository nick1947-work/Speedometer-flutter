import 'dart:math' as math;

/// 1D Kalman filter for smoothing noisy GPS speed measurements.
class SpeedKalmanFilter {
  double _q = 0.05; // Process noise covariance
  double _r = 0.8;  // Measurement noise covariance
  double _x = 0.0;  // Filtered speed estimate (km/h)
  double _p = 1.0;  // Estimation error covariance
  double _k = 0.0;  // Kalman gain

  SpeedKalmanFilter({double processNoise = 0.05, double measurementNoise = 0.8}) {
    _q = processNoise;
    _r = measurementNoise;
  }

  /// Updates filter with new raw measurement in km/h.
  /// Applies a stationary deadband (< 1.5 km/h snaps to 0.0 to prevent drifting when stopped).
  double update(double measurementKmh, {double accuracyMeters = 5.0}) {
    // If stationary threshold
    if (measurementKmh < 1.5) {
      _x = 0.0;
      _p = 1.0;
      return 0.0;
    }

    // Dynamic measurement noise based on GPS accuracy
    final dynamicR = _r * math.max(1.0, accuracyMeters / 5.0);

    // Prediction update
    _p = _p + _q;

    // Measurement update
    _k = _p / (_p + dynamicR);
    _x = _x + _k * (measurementKmh - _x);
    _p = (1.0 - _k) * _p;

    return math.max(0.0, _x);
  }

  void reset() {
    _x = 0.0;
    _p = 1.0;
  }
}
