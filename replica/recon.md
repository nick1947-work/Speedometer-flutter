# Recon map: Speedometer: GPS Speedometer (Android)

Scope: Real-time GPS speed tracking, digital/analog/HUD dashboard, speed limit alerts, trip odometer, and history logging.
For: Standalone, clean, battery-efficient Android app without aggressive ads, targeting drivers, cyclists, and commuters.
Date: 2026-10-14

## Sources

| # | source | URL | notes |
| --- | --- | --- | --- |
| 1 | Google Play Store Listing | `https://play.google.com/store/apps/details?id=gps.speedometer.gpsspeedometer.odometer` | Simple Design Ltd. (4.8 rating, 50M+ installs). Details features, HUD mode, offline GPS, speed limit alerts. |
| 2 | Reference Screenshots | `replica/screens/screen_01.png` - `screen_08.png` | In-app layouts for Digital Speedometer, Analog Dial, HUD mode, Map tracking, Settings, and Trip History. |

## Core loop

Users start speed tracking to view real-time velocity, distance, and time across Digital, Analog, or HUD modes, and receive alerts when exceeding user-set speed limits.

## Screens

| ID | screen | route / how to reach | purpose | key components | states seen |
| --- | --- | --- | --- | --- | --- |
| S01 | Main Dashboard (Digital Speedometer) | App launch / Home | Primary driving interface showing real-time speed, unit selector, and trip metrics. | Huge digital speed readout, unit toggle (km/h, mph, knot), metric chips (max speed, avg speed, trip distance, duration), control buttons (Start/Pause/Reset, HUD, Map, Settings, Speed Limit). | Idle (0 speed), active driving, paused, warning state (exceeding speed limit). |
| S02 | Analog Speedometer View | Toggle view mode from S01 | Classic automotive circular gauge layout for drivers preferring needle gauges. | Circular dial with dynamic needle animation, digital inset, trip metrics bar. | Idle, active acceleration, redline alert. |
| S03 | Head-Up Display (HUD) Mode | HUD button on S01 / S02 | Reflection mode projected onto car windshield at night. | Inverted / mirrored monochrome display, high-contrast oversized speed digits, speed limit indicator. | Mirrored active, mirrored alert. |
| S04 | Live Map Tracking View | Map button on S01 | Real-time map showing current GPS position and recorded trail. | Map container (OpenStreetMap / Google Maps), polyline route path, speed overlay pill, center-on-user FAB. | Locating, tracking path, GPS signal lost. |
| S05 | Speed Limit Alert Setup | Warning / Bell icon on S01 | Configure speed limit threshold and alarm notification styles. | Speed slider / stepper, audio alarm toggle, vibration toggle, voice alert toggle, test sound button. | Default, configured limit active. |
| S06 | Trip History List | History tab / button from S01 | List of recorded past trips and sessions. | Chronological trip card list, date/time chips, total distance, max speed, delete/clear actions. | Empty history, populated list. |
| S07 | Trip Detail Summary | Tap on a trip in S06 | In-depth breakdown of a completed journey. | Mini-map with completed route polyline, start/end timestamps, distance, elapsed time, avg speed, max speed, elevation/speed graphs. | Loaded summary. |
| S08 | Settings & Theme Customization | Settings icon on S01 | Configure measurement units, display colors, and system overlay. | Unit picker (km/h, mph, knots), theme color palette (Neon Green, Cyan, Red, Orange, Purple), screen keep-alive toggle, floating window toggle. | Default options, saved preferences. |
| S09 | Floating Window (PiP Overlay) | Toggle from Settings / Quick Action | Compact speed indicator floating over Google Maps or other navigation apps. | Draggable compact pill with live speed and warning ring, close button. | Floating idle, floating alert. |

## Flows

```
F01 Quick Start Speed Tracking & Odometer
    S01 (tap Start) -> User accelerates -> Live speed, odometer, and trip time update -> S01 (tap Pause/Stop)
    happy path clicks: 1
    edge: GPS disabled, permission denied, poor satellite fix, phone switched between portrait & landscape.

F02 Speed Limit Exceeded Warning
    S01 -> S05 (Set limit e.g. 80 km/h, enable sound + vibration) -> S01 -> Speed exceeds 80 km/h -> Visual red flash + audio alarm triggers -> Speed drops below 80 km/h -> Normal state resumes
    happy path clicks: 3
    edge: Device muted, Bluetooth audio latency, rapid oscillation around speed limit threshold.

F03 Windshield Reflection (HUD Mode)
    S01 -> S03 (HUD button) -> Screen horizontally mirrors -> Phone placed on dashboard facing windshield -> Tap screen to exit back to S01
    happy path clicks: 1
    edge: Screen auto-rotation locks orientation, brightness too low for daylight reflection.

F04 Review Recorded Trip in History
    S01 -> Trip stopped and saved -> S06 (History) -> Tap trip item -> S07 (Trip Detail with map and metrics)
    happy path clicks: 2
    edge: Short trip (< 50 meters) discarded or logged, corrupted GPS log points.
```

## Components

| component | variants | states | used on |
| --- | --- | --- | --- |
| DigitalSpeedDisplay | Standard, HUD mirrored | Zero/idle, normal running, overspeed alert (red flash) | S01, S03, S09 |
| AnalogGauge | Circular dial with rotating needle | Zero, accelerating, over-limit redline | S02 |
| MetricTile | Distance, Elapsed Time, Avg Speed, Max Speed | Default, updating, reset | S01, S02, S07 |
| SpeedUnitSelector | Segmented button (km/h, mph, knot) | Selected, unselected | S01, S08 |
| TripControlBar | Start, Pause, Resume, Reset | Default, active recording, paused | S01, S02 |
| RouteMap | Live trail, static summary route | Interactive, follow user, static overview | S04, S07 |
| SpeedLimitModal | Modal sheet with slider and toggles | Open, adjusting, saving | S05 |
| ThemeColorPicker | Grid of color swatch chips | Selected, unselected | S08 |
| FloatingBubble | Draggable PiP pill | Normal speed, warning flash | S09 |

## Inferred data model

```
Trip
    id: string (UUID)
    startTime: timestamp
    endTime: timestamp
    totalDistanceMeters: float
    durationSeconds: integer
    maxSpeedKmh: float
    avgSpeedKmh: float
    speedUnit: enum (KMH, MPH, KNOT)
    waypoints: list of Waypoint
    evidence: S01, S06, S07, Play Store listing
    confidence: high

Waypoint
    latitude: double
    longitude: double
    speedKmh: float
    altitudeMeters: double
    timestamp: timestamp
    evidence: S04, S07 (GPS route trail on map)
    confidence: high

UserPreferences
    unit: enum (KMH, MPH, KNOT)
    speedLimitThreshold: float
    speedLimitAlertAudio: boolean
    speedLimitAlertVibrate: boolean
    speedLimitAlertVoice: boolean
    themeColor: string (Hex)
    keepScreenOn: boolean
    floatingWindowEnabled: boolean
    evidence: S05, S08, Play Store feature list
    confidence: high
```

Relationships:
- 1 `UserPreferences` per installation.
- 1 `Trip` contains 0..n `Waypoint` records.

## Feature matrix

See `replica/features.csv`.
- Must: 11
- Should: 4
- Could: 3
- Skip: 2 (Third-party ad banners/interstitials and aggressive network tracking)

## Out of scope (cannot or should not be cloned)

- Third-party advertising SDKs (AdMob, IronSource, UnityAds) that ruin user experience in the original app.
- Aggressive background analytics and data brokers.
- Paywalls that charge weekly subscriptions for basic speedometer functionality.

## Size

Screens: 9, Flows: 4, Entities: 3.
Hard parts: Accurate low-latency GPS speed smoothing filter (Kalman/moving average to prevent GPS jitter), foreground service lifecycle to record speed while backgrounded, and mirror transformation for HUD mode.
Size: **M (Medium)**.
