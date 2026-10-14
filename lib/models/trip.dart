import '../core/constants/speed_units.dart';
import 'waypoint.dart';

class Trip {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final double totalDistanceMeters;
  final int durationSeconds;
  final double maxSpeedKmh;
  final double avgSpeedKmh;
  final SpeedUnit speedUnit;
  final List<Waypoint> waypoints;

  Trip({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.totalDistanceMeters,
    required this.durationSeconds,
    required this.maxSpeedKmh,
    required this.avgSpeedKmh,
    this.speedUnit = SpeedUnit.kmh,
    this.waypoints = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'total_distance_meters': totalDistanceMeters,
      'duration_seconds': durationSeconds,
      'max_speed_kmh': maxSpeedKmh,
      'avg_speed_kmh': avgSpeedKmh,
      'speed_unit': speedUnit.name.toUpperCase(),
    };
  }

  factory Trip.fromMap(Map<String, dynamic> map, [List<Waypoint> waypoints = const []]) {
    SpeedUnit unit;
    try {
      unit = SpeedUnit.values.byName((map['speed_unit'] as String).toLowerCase());
    } catch (_) {
      unit = SpeedUnit.kmh;
    }

    return Trip(
      id: map['id'] as String,
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int),
      endTime: map['end_time'] != null ? DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int) : null,
      totalDistanceMeters: (map['total_distance_meters'] as num).toDouble(),
      durationSeconds: map['duration_seconds'] as int,
      maxSpeedKmh: (map['max_speed_kmh'] as num).toDouble(),
      avgSpeedKmh: (map['avg_speed_kmh'] as num).toDouble(),
      speedUnit: unit,
      waypoints: waypoints,
    );
  }

  Trip copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    double? totalDistanceMeters,
    int? durationSeconds,
    double? maxSpeedKmh,
    double? avgSpeedKmh,
    SpeedUnit? speedUnit,
    List<Waypoint>? waypoints,
  }) {
    return Trip(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalDistanceMeters: totalDistanceMeters ?? this.totalDistanceMeters,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
      avgSpeedKmh: avgSpeedKmh ?? this.avgSpeedKmh,
      speedUnit: speedUnit ?? this.speedUnit,
      waypoints: waypoints ?? this.waypoints,
    );
  }
}
