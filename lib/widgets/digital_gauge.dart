import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/speed_units.dart';

class DigitalGauge extends StatelessWidget {
  final double speedKmh;
  final SpeedUnit unit;
  final double speedLimitKmh;
  final bool isOverSpeed;
  final Color themeColor;
  final double accuracyMeters;
  final double altitudeMeters;

  const DigitalGauge({
    super.key,
    required this.speedKmh,
    required this.unit,
    required this.speedLimitKmh,
    required this.isOverSpeed,
    required this.themeColor,
    required this.accuracyMeters,
    required this.altitudeMeters,
  });

  @override
  Widget build(BuildContext context) {
    final displaySpeed = unit.fromKmh(speedKmh).round();
    final displayLimit = unit.fromKmh(speedLimitKmh).round();
    final activeColor = isOverSpeed ? AppColors.alertRed : themeColor;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Speed Limit Sign (European/International road sign style)
        if (speedLimitKmh > 0)
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isOverSpeed ? AppColors.alertRed : Colors.white.withOpacity(0.8),
                width: 3.5,
              ),
              color: isOverSpeed ? AppColors.alertRed.withOpacity(0.2) : Colors.black45,
            ),
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              child: Text(
                '$displayLimit',
                style: TextStyle(
                  color: isOverSpeed ? AppColors.alertRed : Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
          ),

        const SizedBox(height: 12),

        // Oversized Digital Speed Readout
        FittedBox(
          fit: BoxFit.scaleDown,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
            style: TextStyle(
              fontSize: 130,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
              letterSpacing: -4,
              color: activeColor,
              shadows: [
                Shadow(
                  color: activeColor.withOpacity(isOverSpeed ? 0.8 : 0.4),
                  blurRadius: isOverSpeed ? 30 : 15,
                ),
              ],
            ),
            child: Text(
              displaySpeed < 10 ? '0$displaySpeed' : '$displaySpeed',
            ),
          ),
        ),

        // Unit Tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: activeColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: activeColor.withOpacity(0.4), width: 1),
          ),
          child: Text(
            unit.label.toUpperCase(),
            style: TextStyle(
              color: activeColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // GPS Satellite Accuracy & Altitude pill
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _InfoChip(
              icon: Icons.gps_fixed,
              label: 'GPS ±${accuracyMeters.toStringAsFixed(0)}m',
            ),
            const SizedBox(width: 12),
            _InfoChip(
              icon: Icons.terrain,
              label: '${altitudeMeters.toStringAsFixed(0)}m alt',
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
