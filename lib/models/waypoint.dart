class Waypoint {
  final int? id;
  final String tripId;
  final double latitude;
  final double longitude;
  final double speedKmh;
  final double? altitudeMeters;
  final DateTime timestamp;

  Waypoint({
    this.id,
    required this.tripId,
    required this.latitude,
    required this.longitude,
    required this.speedKmh,
    this.altitudeMeters,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'trip_id': tripId,
      'latitude': latitude,
      'longitude': longitude,
      'speed_kmh': speedKmh,
      'altitude_meters': altitudeMeters,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory Waypoint.fromMap(Map<String, dynamic> map) {
    return Waypoint(
      id: map['id'] as int?,
      tripId: map['trip_id'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      speedKmh: (map['speed_kmh'] as num).toDouble(),
      altitudeMeters: map['altitude_meters'] != null ? (map['altitude_meters'] as num).toDouble() : null,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }
}
