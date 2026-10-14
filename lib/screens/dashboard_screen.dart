import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/speed_units.dart';
import '../models/user_settings.dart';
import '../providers/location_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/trip_provider.dart';
import '../widgets/analog_gauge.dart';
import '../widgets/digital_gauge.dart';
import '../widgets/metric_tile.dart';
import '../widgets/speed_limit_modal.dart';
import 'history_screen.dart';
import 'map_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isHudMode = false;

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final gps = ref.watch(locationProvider);
    final trip = ref.watch(activeTripProvider);
    final settings = ref.watch(settingsProvider);
    final unit = settings.unit;

    Widget content = Scaffold(
      backgroundColor: _isHudMode ? Colors.black : AppColors.background,
      appBar: _isHudMode
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: settings.themeColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.speed, color: settings.themeColor, size: 20),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'SpeedMaster',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              actions: [
                // Quick Speed Unit Cycle
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: settings.themeColor,
                      side: BorderSide(color: settings.themeColor.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    onPressed: () {
                      final nextIndex = (unit.index + 1) % SpeedUnit.values.length;
                      ref.read(settingsProvider.notifier).setUnit(SpeedUnit.values[nextIndex]);
                    },
                    child: Text(
                      unit.label.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Speed Limit Alert',
                  icon: Icon(
                    Icons.warning_amber_rounded,
                    color: trip.isOverSpeedLimit ? AppColors.alertRed : Colors.white70,
                  ),
                  onPressed: () => SpeedLimitModal.show(context),
                ),
                IconButton(
                  tooltip: 'HUD Windshield Mode',
                  icon: const Icon(Icons.flip, color: Colors.white70),
                  onPressed: () => setState(() => _isHudMode = true),
                ),
                IconButton(
                  tooltip: 'Map View',
                  icon: const Icon(Icons.map_outlined, color: Colors.white70),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MapScreen()),
                  ),
                ),
                IconButton(
                  tooltip: 'Trip History',
                  icon: const Icon(Icons.history_rounded, color: Colors.white70),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  ),
                ),
                IconButton(
                  tooltip: 'Settings',
                  icon: const Icon(Icons.settings_outlined, color: Colors.white70),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
      body: SafeArea(
        child: Column(
          children: [
            // Location Error Warning Banner
            if (gps.errorMessage != null && !_isHudMode)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.alertRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.alertRed.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.alertRed, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        gps.errorMessage!,
                        style: const TextStyle(color: AppColors.alertRed, fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref.read(locationProvider.notifier).initGps(),
                      child: const Text('Retry', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ],
                ),
              ),

            // Mode Selector Pill (Digital / Analog)
            if (!_isHudMode)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ModeTab(
                      label: 'DIGITAL',
                      icon: Icons.pin_outlined,
                      isSelected: settings.dashboardMode == DashboardMode.digital,
                      themeColor: settings.themeColor,
                      onTap: () => ref.read(settingsProvider.notifier).setDashboardMode(DashboardMode.digital),
                    ),
                    const SizedBox(width: 8),
                    _ModeTab(
                      label: 'ANALOG',
                      icon: Icons.av_timer_outlined,
                      isSelected: settings.dashboardMode == DashboardMode.analog,
                      themeColor: settings.themeColor,
                      onTap: () => ref.read(settingsProvider.notifier).setDashboardMode(DashboardMode.analog),
                    ),
                  ],
                ),
              ),

            // Main Speedometer Gauge
            Expanded(
              child: Center(
                child: settings.dashboardMode == DashboardMode.digital
                    ? DigitalGauge(
                        speedKmh: gps.currentSpeedKmh,
                        unit: unit,
                        speedLimitKmh: settings.speedLimitKmh,
                        isOverSpeed: trip.isOverSpeedLimit,
                        themeColor: settings.themeColor,
                        accuracyMeters: gps.accuracyMeters,
                        altitudeMeters: gps.altitudeMeters,
                      )
                    : AnalogGauge(
                        speedKmh: gps.currentSpeedKmh,
                        unit: unit,
                        speedLimitKmh: settings.speedLimitKmh,
                        isOverSpeed: trip.isOverSpeedLimit,
                        themeColor: settings.themeColor,
                      ),
              ),
            ),

            // Metrics Grid (Distance, Duration, Max Speed, Avg Speed)
            if (!_isHudMode)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: MetricTile(
                            label: 'Distance',
                            value: unit.formatDistance(trip.distanceMeters),
                            unit: unit.distanceUnitLabel(),
                            icon: Icons.straighten,
                            accentColor: settings.themeColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: MetricTile(
                            label: 'Time',
                            value: _formatDuration(trip.elapsedSeconds),
                            unit: '',
                            icon: Icons.timer_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
                            label: 'Avg Speed',
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

            // Trip Control Action Bar
            if (!_isHudMode)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 4),
                child: Row(
                  children: [
                    if (trip.status == TripStatus.idle)
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: settings.themeColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, size: 24),
                          label: const Text(
                            'START TRIP',
                            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0),
                          ),
                          onPressed: () => ref.read(activeTripProvider.notifier).startTrip(),
                        ),
                      )
                    else ...[
                      // Pause or Resume
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: trip.status == TripStatus.recording
                                ? AppColors.surfaceLight
                                : settings.themeColor,
                            foregroundColor: trip.status == TripStatus.recording
                                ? Colors.white
                                : Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: Icon(
                            trip.status == TripStatus.recording
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                          label: Text(
                            trip.status == TripStatus.recording ? 'PAUSE' : 'RESUME',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          onPressed: () {
                            if (trip.status == TripStatus.recording) {
                              ref.read(activeTripProvider.notifier).pauseTrip();
                            } else {
                              ref.read(activeTripProvider.notifier).resumeTrip();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Stop and Save
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.alertRed.withOpacity(0.2),
                            foregroundColor: AppColors.alertRed,
                            side: const BorderSide(color: AppColors.alertRed, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.stop_rounded),
                          label: const Text(
                            'STOP & SAVE',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          onPressed: () async {
                            await ref.read(activeTripProvider.notifier).stopAndSaveTrip();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Trip saved to history!'),
                                  backgroundColor: AppColors.surfaceLight,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // HUD Exit instruction banner
            if (_isHudMode)
              GestureDetector(
                onTap: () => setState(() => _isHudMode = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  color: Colors.transparent,
                  child: const Text(
                    'HUD ACTIVE • TAP ANYWHERE TO EXIT',
                    style: TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    // If HUD Mode is active, flip horizontally with Matrix4.rotationY(pi)
    if (_isHudMode) {
      return GestureDetector(
        onTap: () => setState(() => _isHudMode = false),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.rotationY(math.pi),
          child: content,
        ),
      );
    }

    return content;
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color themeColor;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.themeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? themeColor.withOpacity(0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? themeColor : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? themeColor : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? themeColor : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
