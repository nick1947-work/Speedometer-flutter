import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../core/constants/speed_units.dart';
import '../core/database/app_database.dart';
import '../models/user_settings.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, UserSettings>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<UserSettings> {
  SettingsNotifier() : super(const UserSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await AppDatabase.instance.getSettings();
    state = settings;
    _applyWakelock(settings.keepScreenOn);
  }

  void _applyWakelock(bool keepOn) {
    try {
      if (keepOn) {
        WakelockPlus.enable();
      } else {
        WakelockPlus.disable();
      }
    } catch (_) {}
  }

  Future<void> setUnit(SpeedUnit unit) async {
    state = state.copyWith(unit: unit);
    await AppDatabase.instance.saveSettings(state);
  }

  Future<void> setSpeedLimit(double limitKmh) async {
    state = state.copyWith(speedLimitKmh: limitKmh);
    await AppDatabase.instance.saveSettings(state);
  }

  Future<void> setThemeColor(Color color) async {
    state = state.copyWith(themeColor: color);
    await AppDatabase.instance.saveSettings(state);
  }

  Future<void> toggleAudio(bool enabled) async {
    state = state.copyWith(alertAudioEnabled: enabled);
    await AppDatabase.instance.saveSettings(state);
  }

  Future<void> toggleVibration(bool enabled) async {
    state = state.copyWith(alertVibrateEnabled: enabled);
    await AppDatabase.instance.saveSettings(state);
  }

  Future<void> toggleKeepScreenOn(bool keepOn) async {
    state = state.copyWith(keepScreenOn: keepOn);
    _applyWakelock(keepOn);
    await AppDatabase.instance.saveSettings(state);
  }

  Future<void> setDashboardMode(DashboardMode mode) async {
    state = state.copyWith(dashboardMode: mode);
    await AppDatabase.instance.saveSettings(state);
  }
}
