import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/speed_units.dart';

enum DashboardMode { digital, analog }

class UserSettings {
  final SpeedUnit unit;
  final double speedLimitKmh;
  final bool alertAudioEnabled;
  final bool alertVibrateEnabled;
  final Color themeColor;
  final bool keepScreenOn;
  final DashboardMode dashboardMode;

  const UserSettings({
    this.unit = SpeedUnit.kmh,
    this.speedLimitKmh = 80.0,
    this.alertAudioEnabled = true,
    this.alertVibrateEnabled = true,
    this.themeColor = AppColors.neonGreen,
    this.keepScreenOn = true,
    this.dashboardMode = DashboardMode.digital,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': 1,
      'unit': unit.name.toUpperCase(),
      'speed_limit_kmh': speedLimitKmh,
      'alert_audio_enabled': alertAudioEnabled ? 1 : 0,
      'alert_vibrate_enabled': alertVibrateEnabled ? 1 : 0,
      'theme_color': '#${themeColor.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}',
      'keep_screen_on': keepScreenOn ? 1 : 0,
      'display_mode': dashboardMode.name.toUpperCase(),
    };
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    SpeedUnit unit;
    try {
      unit = SpeedUnit.values.byName((map['unit'] as String).toLowerCase());
    } catch (_) {
      unit = SpeedUnit.kmh;
    }

    DashboardMode mode;
    try {
      mode = DashboardMode.values.byName((map['display_mode'] as String).toLowerCase());
    } catch (_) {
      mode = DashboardMode.digital;
    }

    Color color;
    try {
      final hex = (map['theme_color'] as String).replaceFirst('#', '');
      color = Color(int.parse(hex, radix: 16));
    } catch (_) {
      color = AppColors.neonGreen;
    }

    return UserSettings(
      unit: unit,
      speedLimitKmh: (map['speed_limit_kmh'] as num).toDouble(),
      alertAudioEnabled: (map['alert_audio_enabled'] as int) == 1,
      alertVibrateEnabled: (map['alert_vibrate_enabled'] as int) == 1,
      themeColor: color,
      keepScreenOn: (map['keep_screen_on'] as int) == 1,
      dashboardMode: mode,
    );
  }

  UserSettings copyWith({
    SpeedUnit? unit,
    double? speedLimitKmh,
    bool? alertAudioEnabled,
    bool? alertVibrateEnabled,
    Color? themeColor,
    bool? keepScreenOn,
    DashboardMode? dashboardMode,
  }) {
    return UserSettings(
      unit: unit ?? this.unit,
      speedLimitKmh: speedLimitKmh ?? this.speedLimitKmh,
      alertAudioEnabled: alertAudioEnabled ?? this.alertAudioEnabled,
      alertVibrateEnabled: alertVibrateEnabled ?? this.alertVibrateEnabled,
      themeColor: themeColor ?? this.themeColor,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      dashboardMode: dashboardMode ?? this.dashboardMode,
    );
  }
}
