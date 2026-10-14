import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/speed_units.dart';

class AnalogGauge extends StatelessWidget {
  final double speedKmh;
  final SpeedUnit unit;
  final double speedLimitKmh;
  final bool isOverSpeed;
  final Color themeColor;

  const AnalogGauge({
    super.key,
    required this.speedKmh,
    required this.unit,
    required this.speedLimitKmh,
    required this.isOverSpeed,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final displaySpeed = unit.fromKmh(speedKmh);
    final displayLimit = unit.fromKmh(speedLimitKmh);
    final maxScale = unit == SpeedUnit.mph ? 160.0 : (unit == SpeedUnit.knot ? 140.0 : 240.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight) * 0.95;

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _AnalogGaugePainter(
                  currentSpeed: displaySpeed,
                  speedLimit: displayLimit,
                  maxScale: maxScale,
                  unitLabel: unit.label.toUpperCase(),
                  isOverSpeed: isOverSpeed,
                  themeColor: themeColor,
                ),
              ),
              // Center Digital Inset
              Positioned(
                bottom: size * 0.22,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displaySpeed.toStringAsFixed(0),
                      style: TextStyle(
                        color: isOverSpeed ? AppColors.alertRed : themeColor,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      unit.label.toUpperCase(),
                      style: TextStyle(
                        color: isOverSpeed ? AppColors.alertRed : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnalogGaugePainter extends CustomPainter {
  final double currentSpeed;
  final double speedLimit;
  final double maxScale;
  final String unitLabel;
  final bool isOverSpeed;
  final Color themeColor;

  _AnalogGaugePainter({
    required this.currentSpeed,
    required this.speedLimit,
    required this.maxScale,
    required this.unitLabel,
    required this.isOverSpeed,
    required this.themeColor,
  });

  static const double startAngle = 135 * (math.pi / 180); // Bottom-left
  static const double totalAngle = 270 * (math.pi / 180); // 270-degree sweep

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;

    // Background dial circle
    final bgPaint = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius + 12, bgPaint);

    final borderPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius + 12, borderPaint);

    // Track arc
    final trackPaint = Paint()
      ..color = AppColors.surfaceLight
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8.0;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      totalAngle,
      false,
      trackPaint,
    );

    // Speed Limit Redline Arc
    if (speedLimit > 0 && speedLimit < maxScale) {
      final limitFraction = (speedLimit / maxScale).clamp(0.0, 1.0);
      final limitStartAngle = startAngle + (totalAngle * limitFraction);
      final limitSweepAngle = totalAngle * (1.0 - limitFraction);

      final redlinePaint = Paint()
        ..color = AppColors.alertRed.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 8.0;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        limitStartAngle,
        limitSweepAngle,
        false,
        redlinePaint,
      );
    }

    // Active speed progress arc
    final speedFraction = (currentSpeed / maxScale).clamp(0.0, 1.0);
    final activePaint = Paint()
      ..color = isOverSpeed ? AppColors.alertRed : themeColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8.0;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      totalAngle * speedFraction,
      false,
      activePaint,
    );

    // Major and minor ticks
    const step = 20;
    final totalSteps = (maxScale / step).round();

    for (int i = 0; i <= totalSteps; i++) {
      final val = i * step;
      final fraction = val / maxScale;
      final angle = startAngle + (totalAngle * fraction);

      final tickOuter = Offset(
        center.dx + (radius - 4) * math.cos(angle),
        center.dy + (radius - 4) * math.sin(angle),
      );
      final tickInner = Offset(
        center.dx + (radius - 18) * math.cos(angle),
        center.dy + (radius - 18) * math.sin(angle),
      );

      final isMajor = i % 2 == 0;
      final tickPaint = Paint()
        ..color = val > speedLimit && speedLimit > 0 ? AppColors.alertRed : AppColors.textSecondary
        ..strokeWidth = isMajor ? 2.5 : 1.2;

      canvas.drawLine(tickInner, tickOuter, tickPaint);

      // Draw number labels on major ticks
      if (isMajor) {
        final textPos = Offset(
          center.dx + (radius - 34) * math.cos(angle),
          center.dy + (radius - 34) * math.sin(angle),
        );

        final textSpan = TextSpan(
          text: '$val',
          style: TextStyle(
            color: val > speedLimit && speedLimit > 0 ? AppColors.alertRed : AppColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        );

        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          Offset(
            textPos.dx - textPainter.width / 2,
            textPos.dy - textPainter.height / 2,
          ),
        );
      }
    }

    // Needle
    final needleAngle = startAngle + (totalAngle * speedFraction);
    final needleLength = radius - 24;

    final needleTip = Offset(
      center.dx + needleLength * math.cos(needleAngle),
      center.dy + needleLength * math.sin(needleAngle),
    );

    final needlePaint = Paint()
      ..color = isOverSpeed ? AppColors.alertRed : Colors.white
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, needleTip, needlePaint);

    // Center hub pin
    final hubBorderPaint = Paint()..color = themeColor;
    canvas.drawCircle(center, 9, hubBorderPaint);

    final hubCenterPaint = Paint()..color = AppColors.surface;
    canvas.drawCircle(center, 5, hubCenterPaint);
  }

  @override
  bool shouldRepaint(covariant _AnalogGaugePainter oldDelegate) {
    return oldDelegate.currentSpeed != currentSpeed ||
        oldDelegate.speedLimit != speedLimit ||
        oldDelegate.themeColor != themeColor ||
        oldDelegate.isOverSpeed != isOverSpeed;
  }
}
