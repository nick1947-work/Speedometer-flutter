# Architecture: SpeedMaster GPS (Flutter Android App)

Rebuilding the core features of **Speedometer: GPS Speedometer & Odometer** as a clean, battery-efficient, offline-first Android application ready for the Google Play Store.

## Stack

| layer | choice | why |
| --- | --- | --- |
| **Framework** | **Flutter (Dart 3.x)** | Delivers 60/120fps hardware-accelerated animations for analog gauge needles and digital typography; easy canvas flip for HUD mode. |
| **Platform Target** | **Android (API 24+)** | Direct compile to Play Store Android App Bundle (`.aab`) with ProGuard/R8. |
| **State Management** | **Flutter Riverpod (or Provider)** | Clean separation of GPS stream, trip lifecycle, and UI rendering; easily testable. |
| **GPS / Location Engine** | **`geolocator` + Dart Kalman Filter** | High-accuracy hardware GPS stream (1 Hz) filtered with a moving-average/Kalman speed smoother to eliminate GPS jitter. |
| **Background Execution** | **`flutter_foreground_task`** | Keeps GPS tracking alive in an Android Foreground Service with live notification when the phone is locked or navigation apps are open. |
| **Database** | **`sqflite` (Local SQLite)** | 100% offline, zero-latency, local storage for trips, waypoints, and user settings without any backend server cost. |
| **Mapping** | **`flutter_map` + `latlong2`** | OpenStreetMap raster rendering with local tile cache; zero API key billing or usage limits compared to Google Maps SDK. |
| **Audio & Alerts** | **`audioplayers` + `vibration`** | Immediate chime/alarm tone and haptic feedback upon exceeding speed limit. |
| **Screen Management** | **`wakelock_plus`** | Prevents screen sleep while actively tracking on car dashboard mounts. |

## Schema (SQLite Local)

Tables: 3. Access rules: Purely on-device sandbox.

```sql
-- Trips table: completed or active journeys
CREATE TABLE trips (
  id TEXT PRIMARY KEY,
  start_time INTEGER NOT NULL,
  end_time INTEGER,
  total_distance_meters REAL NOT NULL DEFAULT 0.0,
  duration_seconds INTEGER NOT NULL DEFAULT 0,
  max_speed_kmh REAL NOT NULL DEFAULT 0.0,
  avg_speed_kmh REAL NOT NULL DEFAULT 0.0,
  speed_unit TEXT NOT NULL DEFAULT 'KMH' CHECK (speed_unit IN ('KMH', 'MPH', 'KNOT')),
  created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
);
CREATE INDEX idx_trips_start_time ON trips (start_time DESC);

-- Waypoints table: polyline trail for map playback
CREATE TABLE waypoints (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  trip_id TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  speed_kmh REAL NOT NULL,
  altitude_meters REAL,
  timestamp INTEGER NOT NULL
);
CREATE INDEX idx_waypoints_trip ON waypoints (trip_id, timestamp ASC);

-- Settings / Preferences (key-value store or single row)
CREATE TABLE user_settings (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  unit TEXT NOT NULL DEFAULT 'KMH',
  speed_limit_kmh REAL NOT NULL DEFAULT 80.0,
  alert_audio_enabled INTEGER NOT NULL DEFAULT 1,
  alert_vibrate_enabled INTEGER NOT NULL DEFAULT 1,
  theme_color TEXT NOT NULL DEFAULT '#00FF66',
  keep_screen_on INTEGER NOT NULL DEFAULT 1,
  display_mode TEXT NOT NULL DEFAULT 'DIGITAL' CHECK (display_mode IN ('DIGITAL', 'ANALOG'))
);
```

## Internal Architecture & Services

| Service / Controller | Purpose | Inputs | Outputs |
| --- | --- | --- | --- |
| `LocationService` | Listens to device GPS sensor stream | Desired accuracy: high, distance filter: 1m | Raw `Position` stream |
| `SpeedFilter` | Low-pass / Kalman smoothing algorithm | Raw position + sensor speed | Clean instantaneous speed (km/h) |
| `TripController` | Manages Start, Pause, Resume, Stop state | User actions + filtered speed | Real-time odometer, trip duration, max/avg speed |
| `SpeedLimitMonitor` | Compares current speed against threshold | Live speed, threshold setting | Warning state (idle, warning, alarm) |
| `TripRepository` | Persists trips and waypoints in SQLite | Trip model, waypoint list | Saved trip records |

## The parts that bite

- **GPS Jitter at Rest:** GPS positions drift slightly even when parked, causing phantom speed (e.g. 1–3 km/h). *Fix:* Apply a deadzone threshold (< 1.5 km/h snaps to 0.0).
- **Background Battery Killers:** Android Doze mode kills background GPS listeners after a few minutes. *Fix:* Use an Android Foreground Service with `FOREGROUND_SERVICE_LOCATION` permission and persistent status notification.
- **Orientation Switches:** Drivers mount phones in portrait or landscape. *Fix:* Responsive layout scaling that preserves gauge aspect ratios on both orientations.
- **HUD Windshield Glare / Mirroring:** Mirrored UI must have pure black (`#000000`) background with high-contrast neon digits so only the numbers reflect on the glass.

## Build Order

1. **Vertical Slice:**
   - Flutter project initialization with Android configurations & permissions (`ACCESS_FINE_LOCATION`, `FOREGROUND_SERVICE`).
   - Digital Speedometer core view (live GPS speed, km/h toggle, start/pause trip odometer).
2. **Dashboard Views & HUD:**
   - Analog gauge with `CustomPainter`.
   - Mirrored HUD Mode toggle.
   - Speed limit alert modal with sound and vibration.
3. **Map & Trip History:**
   - OpenStreetMap tracking polyline with `flutter_map`.
   - SQLite persistence with `sqflite` for saving past journeys and viewing trip details.
4. **Themes & Polish:**
   - Neon color themes (green, cyan, orange, red).
   - Landscape car mount optimization.
