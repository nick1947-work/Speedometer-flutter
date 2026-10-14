import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../core/constants/app_colors.dart';
import '../providers/location_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/trip_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  bool _followUser = true;

  @override
  Widget build(BuildContext context) {
    final gps = ref.watch(locationProvider);
    final trip = ref.watch(activeTripProvider);
    final settings = ref.watch(settingsProvider);
    final unit = settings.unit;

    final LatLng currentPos = gps.position != null
        ? LatLng(gps.position!.latitude, gps.position!.longitude)
        : const LatLng(0, 0);

    // Convert recorded waypoints into map polylines
    final List<LatLng> trailPoints = trip.waypoints
        .map((w) => LatLng(w.latitude, w.longitude))
        .toList();

    // Auto-center map if followUser is enabled
    if (_followUser && gps.position != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(currentPos, _mapController.camera.zoom);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Live GPS Map', style: TextStyle(color: Colors.white, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: currentPos,
              initialZoom: 16.0,
              onPositionChanged: (pos, hasGesture) {
                if (hasGesture && _followUser) {
                  setState(() => _followUser = false);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.speedometer.gps.gps_speedometer',
              ),
              // Recorded Breadcrumb Trail
              if (trailPoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: trailPoints,
                      strokeWidth: 5.0,
                      color: settings.themeColor,
                    ),
                  ],
                ),
              // User Marker
              if (gps.position != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: currentPos,
                      width: 28,
                      height: 28,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: settings.themeColor,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: settings.themeColor.withOpacity(0.6),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Floating Speed HUD Overlay
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.92),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    unit.formatSpeed(gps.currentSpeedKmh),
                    style: TextStyle(
                      color: trip.isOverSpeedLimit ? AppColors.alertRed : settings.themeColor,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        unit.label.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${unit.formatDistance(trip.distanceMeters)} ${unit.distanceUnitLabel()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Recenter FAB
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: _followUser ? settings.themeColor : AppColors.surface,
              foregroundColor: _followUser ? Colors.black : Colors.white,
              child: const Icon(Icons.my_location),
              onPressed: () {
                setState(() => _followUser = true);
                if (gps.position != null) {
                  _mapController.move(currentPos, 16.0);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
