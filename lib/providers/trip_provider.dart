import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import 'package:vibration/vibration.dart';
import '../core/database/app_database.dart';
import '../models/trip.dart';
import '../models/waypoint.dart';
import 'location_provider.dart';
import 'settings_provider.dart';

enum TripStatus { idle, recording, paused }

class ActiveTripState {
  final TripStatus status;
  final String? tripId;
  final DateTime? startTime;
  final double distanceMeters;
  final int elapsedSeconds;
  final double maxSpeedKmh;
  final double avgSpeedKmh;
  final List<Waypoint> waypoints;
  final bool isOverSpeedLimit;

  const ActiveTripState({
    this.status = TripStatus.idle,
    this.tripId,
    this.startTime,
    this.distanceMeters = 0.0,
    this.elapsedSeconds = 0,
    this.maxSpeedKmh = 0.0,
    this.avgSpeedKmh = 0.0,
    this.waypoints = const [],
    this.isOverSpeedLimit = false,
  });

  ActiveTripState copyWith({
    TripStatus? status,
    String? tripId,
    DateTime? startTime,
    double? distanceMeters,
    int? elapsedSeconds,
    double? maxSpeedKmh,
    double? avgSpeedKmh,
    List<Waypoint>? waypoints,
    bool? isOverSpeedLimit,
  }) {
    return ActiveTripState(
      status: status ?? this.status,
      tripId: tripId ?? this.tripId,
      startTime: startTime ?? this.startTime,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
      avgSpeedKmh: avgSpeedKmh ?? this.avgSpeedKmh,
      waypoints: waypoints ?? this.waypoints,
      isOverSpeedLimit: isOverSpeedLimit ?? this.isOverSpeedLimit,
    );
  }
}

final activeTripProvider = StateNotifierProvider<ActiveTripNotifier, ActiveTripState>((ref) {
  return ActiveTripNotifier(ref);
});

final tripHistoryProvider = FutureProvider.autoDispose<List<Trip>>((ref) async {
  return await AppDatabase.instance.getAllTrips();
});

class ActiveTripNotifier extends StateNotifier<ActiveTripState> {
  final Ref _ref;
  Timer? _ticker;
  Position? _lastPosition;
  DateTime? _lastAlertTime;

  ActiveTripNotifier(this._ref) : super(const ActiveTripState()) {
    // Listen to location updates
    _ref.listen<GpsState>(locationProvider, (previous, next) {
      _onPositionUpdate(next);
    });
  }

  void _onPositionUpdate(GpsState gps) {
    final speed = gps.currentSpeedKmh;
    final settings = _ref.read(settingsProvider);

    // Speed limit warning logic
    final isOverLimit = settings.speedLimitKmh > 0 && speed > settings.speedLimitKmh;
    if (isOverLimit != state.isOverSpeedLimit) {
      state = state.copyWith(isOverSpeedLimit: isOverLimit);
    }

    if (isOverLimit) {
      _triggerAlertIfNeeded(settings.alertAudioEnabled, settings.alertVibrateEnabled);
    }

    if (state.status != TripStatus.recording || gps.position == null) {
      return;
    }

    final pos = gps.position!;
    double addedDistance = 0.0;

    if (_lastPosition != null) {
      final d = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        pos.latitude,
        pos.longitude,
      );
      // Ignore unreasonable GPS leaps or jitter (< 1m or > 150m/s)
      if (d >= 1.0 && d < 150.0) {
        addedDistance = d;
      }
    }
    _lastPosition = pos;

    final newDistance = state.distanceMeters + addedDistance;
    final newMaxSpeed = speed > state.maxSpeedKmh ? speed : state.maxSpeedKmh;

    // Average speed = (total distance in km) / (elapsed time in hours)
    final double newAvgSpeed;
    if (state.elapsedSeconds > 0) {
      final hours = state.elapsedSeconds / 3600.0;
      newAvgSpeed = (newDistance / 1000.0) / hours;
    } else {
      newAvgSpeed = 0.0;
    }

    final wp = Waypoint(
      tripId: state.tripId!,
      latitude: pos.latitude,
      longitude: pos.longitude,
      speedKmh: speed,
      altitudeMeters: pos.altitude,
      timestamp: DateTime.now(),
    );

    // Save waypoint asynchronously
    AppDatabase.instance.insertWaypoint(wp);

    state = state.copyWith(
      distanceMeters: newDistance,
      maxSpeedKmh: newMaxSpeed,
      avgSpeedKmh: newAvgSpeed,
      waypoints: [...state.waypoints, wp],
    );
  }

  void _triggerAlertIfNeeded(bool audio, bool vibrate) {
    final now = DateTime.now();
    if (_lastAlertTime != null && now.difference(_lastAlertTime!).inSeconds < 3) {
      return; // Rate limit alert to every 3 seconds
    }
    _lastAlertTime = now;

    if (vibrate) {
      try {
        Vibration.hasVibrator().then((has) {
          if (has == true) {
            Vibration.vibrate(pattern: [0, 250, 150, 250]);
          }
        });
      } catch (_) {}
    }

    if (audio) {
      try {
        SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    }
  }

  void startTrip() {
    final tripId = const Uuid().v4();
    final now = DateTime.now();
    _lastPosition = _ref.read(locationProvider).position;

    state = ActiveTripState(
      status: TripStatus.recording,
      tripId: tripId,
      startTime: now,
      distanceMeters: 0.0,
      elapsedSeconds: 0,
      maxSpeedKmh: 0.0,
      avgSpeedKmh: 0.0,
      waypoints: [],
    );

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.status == TripStatus.recording) {
        state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      }
    });
  }

  void pauseTrip() {
    state = state.copyWith(status: TripStatus.paused);
  }

  void resumeTrip() {
    _lastPosition = _ref.read(locationProvider).position;
    state = state.copyWith(status: TripStatus.recording);
  }

  Future<void> stopAndSaveTrip() async {
    _ticker?.cancel();
    if (state.tripId != null && state.startTime != null) {
      final unit = _ref.read(settingsProvider).unit;
      final trip = Trip(
        id: state.tripId!,
        startTime: state.startTime!,
        endTime: DateTime.now(),
        totalDistanceMeters: state.distanceMeters,
        durationSeconds: state.elapsedSeconds,
        maxSpeedKmh: state.maxSpeedKmh,
        avgSpeedKmh: state.avgSpeedKmh,
        speedUnit: unit,
      );

      await AppDatabase.instance.insertTrip(trip);
      _ref.invalidate(tripHistoryProvider);
    }

    resetTrip();
  }

  void resetTrip() {
    _ticker?.cancel();
    _lastPosition = null;
    state = const ActiveTripState(status: TripStatus.idle);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
