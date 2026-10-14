import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../core/constants/app_colors.dart';
import '../core/database/app_database.dart';
import '../models/trip.dart';
import '../providers/settings_provider.dart';
import '../providers/trip_provider.dart';
import '../widgets/metric_tile.dart';

class TripDetailScreen extends ConsumerStatefulWidget {
  final String tripId;

  const TripDetailScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen> {
  Trip? _trip;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrip();
  }

  Future<void> _loadTrip() async {
    final t = await AppDatabase.instance.getTripWithWaypoints(widget.tripId);
    setState(() {
      _trip = t;
      _isLoading = false;
    });
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h}h ${m}m ${s}s';
    }
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final unit = settings.unit;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_trip == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.surface),
        body: const Center(
          child: Text('Trip not found', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final trip = _trip!;
    final points = trip.waypoints.map((w) => LatLng(w.latitude, w.longitude)).toList();
    final center = points.isNotEmpty ? points.first : const LatLng(0, 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          DateFormat('MMM d, yyyy • h:mm a').format(trip.startTime),
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.alertRed),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: const Text('Delete Trip?', style: TextStyle(color: Colors.white)),
                  content: const Text(
                    'This action cannot be undone.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(ctx, false),
                    ),
                    TextButton(
                      child: const Text('Delete', style: TextStyle(color: AppColors.alertRed)),
                      onPressed: () => Navigator.pop(ctx, true),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await AppDatabase.instance.deleteTrip(trip.id);
                ref.invalidate(tripHistoryProvider);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Route Map Preview
            SizedBox(
              height: 260,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 14.0,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.speedometer.gps.gps_speedometer',
                  ),
                  if (points.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: points,
                          strokeWidth: 4.5,
                          color: settings.themeColor,
                        ),
                      ],
                    ),
                  if (points.isNotEmpty)
                    MarkerLayer(
                      markers: [
                        // Start point
                        Marker(
                          point: points.first,
                          child: const Icon(Icons.trip_origin, color: Colors.green, size: 24),
                        ),
                        // End point
                        Marker(
                          point: points.last,
                          child: const Icon(Icons.location_on, color: AppColors.alertRed, size: 28),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Metrics Summary Grid
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: MetricTile(
                          label: 'Total Distance',
                          value: unit.formatDistance(trip.totalDistanceMeters),
                          unit: unit.distanceUnitLabel(),
                          icon: Icons.straighten,
                          accentColor: settings.themeColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: MetricTile(
                          label: 'Duration',
                          value: _formatDuration(trip.durationSeconds),
                          unit: '',
                          icon: Icons.timer_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: MetricTile(
                          label: 'Max Speed',
                          value: unit.formatSpeed(trip.maxSpeedKmh),
                          unit: unit.label,
                          icon: Icons.speed,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: MetricTile(
                          label: 'Average Speed',
                          value: unit.formatSpeed(trip.avgSpeedKmh),
                          unit: unit.label,
                          icon: Icons.trending_up,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
