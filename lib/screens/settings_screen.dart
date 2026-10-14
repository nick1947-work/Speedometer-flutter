import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/speed_units.dart';
import '../models/user_settings.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Settings', style: TextStyle(color: Colors.white, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // Measurement Section
          _SectionHeader(title: 'MEASUREMENT UNITS'),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: SpeedUnit.values.map((unit) {
                return RadioListTile<SpeedUnit>(
                  value: unit,
                  groupValue: settings.unit,
                  activeColor: settings.themeColor,
                  title: Text(
                    unit.label.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    unit.description,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  onChanged: (val) {
                    if (val != null) notifier.setUnit(val);
                  },
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // Appearance & Theme Section
          _SectionHeader(title: 'THEME COLOR'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: AppColors.themePalette.map((color) {
                final isSelected = settings.themeColor.toARGB32() == color.toARGB32();
                return GestureDetector(
                  onTap: () => notifier.setThemeColor(color),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3.5,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: color.withOpacity(0.8), blurRadius: 12)]
                          : [],
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.black, size: 24)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // Display & Power
          _SectionHeader(title: 'DISPLAY & HARDWARE'),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Keep Screen On', style: TextStyle(color: Colors.white)),
                  subtitle: const Text(
                    'Prevents phone screen from dimming while driving',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  value: settings.keepScreenOn,
                  activeColor: settings.themeColor,
                  onChanged: (val) => notifier.toggleKeepScreenOn(val),
                ),
                const Divider(color: AppColors.border, height: 1),
                ListTile(
                  title: const Text('Default Dashboard View', style: TextStyle(color: Colors.white)),
                  subtitle: Text(
                    settings.dashboardMode == DashboardMode.digital ? 'Digital Readout' : 'Analog Dial',
                    style: TextStyle(color: settings.themeColor, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  onTap: () {
                    final nextMode = settings.dashboardMode == DashboardMode.digital
                        ? DashboardMode.analog
                        : DashboardMode.digital;
                    notifier.setDashboardMode(nextMode);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // About section
          _SectionHeader(title: 'ABOUT'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GPS Speedometer & Odometer',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                SizedBox(height: 6),
                Text(
                  'Version 1.0.0 • Clean-Room Edition',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                SizedBox(height: 12),
                Text(
                  '• 100% Offline GPS tracking\n• Zero ads & zero third-party trackers\n• Designed for cars, bikes, boats, and jogging\n• HUD windshield reflection support',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
