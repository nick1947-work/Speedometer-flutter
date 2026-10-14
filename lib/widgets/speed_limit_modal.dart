import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../providers/settings_provider.dart';

class SpeedLimitModal extends ConsumerStatefulWidget {
  const SpeedLimitModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const SpeedLimitModal(),
    );
  }

  @override
  ConsumerState<SpeedLimitModal> createState() => _SpeedLimitModalState();
}

class _SpeedLimitModalState extends ConsumerState<SpeedLimitModal> {
  late double _limit;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _limit = settings.speedLimitKmh;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final unit = settings.unit;
    final convertedLimit = unit.fromKmh(_limit).round();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.alertRed, size: 24),
              SizedBox(width: 8),
              Text(
                'Speed Limit Alert',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Get notified immediately with sound and vibration when you exceed this speed limit.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Speed Limit display
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.alertRed, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$convertedLimit',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    unit.label,
                    style: const TextStyle(
                      color: AppColors.alertRed,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Quick Preset Buttons
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [30.0, 50.0, 60.0, 80.0, 100.0, 120.0].map((presetKmh) {
              final isSelected = (_limit - presetKmh).abs() < 1.0;
              final presetConverted = unit.fromKmh(presetKmh).round();

              return ActionChip(
                label: Text('$presetConverted ${unit.label}'),
                backgroundColor: isSelected ? AppColors.alertRed : AppColors.surfaceLight,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                onPressed: () {
                  setState(() => _limit = presetKmh);
                  ref.read(settingsProvider.notifier).setSpeedLimit(presetKmh);
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Slider
          Slider(
            value: _limit.clamp(10.0, 220.0),
            min: 10.0,
            max: 220.0,
            divisions: 42,
            activeColor: AppColors.alertRed,
            inactiveColor: AppColors.surfaceLight,
            onChanged: (val) {
              setState(() => _limit = val);
              ref.read(settingsProvider.notifier).setSpeedLimit(val);
            },
          ),

          const Divider(color: AppColors.border),

          // Audio toggle
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Sound Warning', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Plays chime sound on overspeed', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            value: settings.alertAudioEnabled,
            activeColor: AppColors.alertRed,
            onChanged: (val) => ref.read(settingsProvider.notifier).toggleAudio(val),
          ),

          // Vibration toggle
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Vibration Warning', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Vibrates phone upon exceeding limit', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            value: settings.alertVibrateEnabled,
            activeColor: AppColors.alertRed,
            onChanged: (val) => ref.read(settingsProvider.notifier).toggleVibration(val),
          ),

          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surfaceLight,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
