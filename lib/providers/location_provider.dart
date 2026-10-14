import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../core/utils/kalman_filter.dart';

class GpsState {
  final double currentSpeedKmh;
  final Position? position;
  final bool isGpsEnabled;
  final bool hasPermission;
  final String? errorMessage;
  final double altitudeMeters;
  final double accuracyMeters;

  const GpsState({
    this.currentSpeedKmh = 0.0,
    this.position,
    this.isGpsEnabled = false,
    this.hasPermission = false,
    this.errorMessage,
    this.altitudeMeters = 0.0,
    this.accuracyMeters = 0.0,
  });

  GpsState copyWith({
    double? currentSpeedKmh,
    Position? position,
    bool? isGpsEnabled,
    bool? hasPermission,
    String? errorMessage,
    double? altitudeMeters,
    double? accuracyMeters,
  }) {
    return GpsState(
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      position: position ?? this.position,
      isGpsEnabled: isGpsEnabled ?? this.isGpsEnabled,
      hasPermission: hasPermission ?? this.hasPermission,
      errorMessage: errorMessage,
      altitudeMeters: altitudeMeters ?? this.altitudeMeters,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
    );
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, GpsState>((ref) {
  return LocationNotifier();
});

class LocationNotifier extends StateNotifier<GpsState> {
  StreamSubscription<Position>? _positionSubscription;
  final SpeedKalmanFilter _filter = SpeedKalmanFilter();

  LocationNotifier() : super(const GpsState()) {
    initGps();
  }

  Future<void> initGps() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          isGpsEnabled: false,
          errorMessage: 'GPS Location Service is disabled on this device.',
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(
            hasPermission: false,
            errorMessage: 'Location permission denied.',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          hasPermission: false,
          errorMessage: 'Location permission permanently denied. Enable in app settings.',
        );
        return;
      }

      state = state.copyWith(isGpsEnabled: true, hasPermission: true, errorMessage: null);
      _startTracking();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  void _startTracking() {
    _positionSubscription?.cancel();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      // position.speed is in meters/second -> convert to km/h (* 3.6)
      final rawSpeedKmh = (position.speed > 0) ? position.speed * 3.6 : 0.0;
      final smoothedSpeed = _filter.update(
        rawSpeedKmh,
        accuracyMeters: position.accuracy,
      );

      state = state.copyWith(
        currentSpeedKmh: smoothedSpeed,
        position: position,
        altitudeMeters: position.altitude,
        accuracyMeters: position.accuracy,
        errorMessage: null,
      );
    }, onError: (err) {
      state = state.copyWith(errorMessage: err.toString());
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}
