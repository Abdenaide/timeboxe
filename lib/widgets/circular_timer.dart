import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CircularTimer extends StatefulWidget {
  final double progress;
  final String timeText;
  final String phaseLabel;
  final String phaseSubLabel;
  final Color phaseColor;
  final bool isWarning;
  final bool isRunning;

  const CircularTimer({
    super.key,
    required this.progress,
    required this.timeText,
    required this.phaseLabel,
    required this.phaseSubLabel,
    required this.phaseColor,
    this.isWarning = false,
    this.isRunning = false,
  });

  @override
  State<CircularTimer> createState() => _CircularTimerState();
}

class _CircularTimerState extends State<CircularTimer>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _warningController;
  late Animation<double> _glowAnimation;
  late Animation<double> _warningAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _warningController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _warningAnimation = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _warningController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(CircularTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isWarning && !oldWidget.isWarning) {
      _warningController.repeat(reverse: true);
    } else if (!widget.isWarning && oldWidget.isWarning) {
      _warningController.stop();
      _warningController.value = 0;
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _warningController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_glowAnimation, _warningAnimation]),
      builder: (context, child) {
        final glowOpacity = widget.isRunning ? _glowAnimation.value : 0.3;
        final warningOpacity = widget.isWarning ? _warningAnimation.value : 1.0;

        return SizedBox(
          width: 300,
          height: 300,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow effect
              if (widget.isRunning)
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.phaseColor.withValues(
                          alpha: glowOpacity * 0.3,
                        ),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),

              // Background circle
              CustomPaint(
                size: const Size(280, 280),
                painter: _CircularTimerPainter(
                  progress: widget.progress,
                  phaseColor: widget.phaseColor,
                  backgroundColor: AppColors.surfaceLight,
                  strokeWidth: 8,
                ),
              ),

              // Inner content
              Opacity(
                opacity: warningOpacity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Phase label
                    Text(
                      widget.phaseLabel,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: widget.phaseColor,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Time
                    Text(
                      widget.timeText,
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(
                            color: AppColors.textPrimary,
                            shadows: [
                              Shadow(
                                color: widget.phaseColor.withValues(alpha: 0.5),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                    ),
                    const SizedBox(height: 8),
                    // Sub label
                    Text(
                      widget.phaseSubLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
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

class _CircularTimerPainter extends CustomPainter {
  final double progress;
  final Color phaseColor;
  final Color backgroundColor;
  final double strokeWidth;

  _CircularTimerPainter({
    required this.progress,
    required this.phaseColor,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = phaseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -pi / 2,
        endAngle: 3 * pi / 2,
        colors: [phaseColor.withValues(alpha: 0.5), phaseColor],
        stops: const [0.0, 1.0],
        transform: const GradientRotation(-pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    // Dot at the end of progress arc
    if (progress > 0 && progress < 1) {
      final dotAngle = -pi / 2 + sweepAngle;
      final dotX = center.dx + radius * cos(dotAngle);
      final dotY = center.dy + radius * sin(dotAngle);

      final dotPaint = Paint()
        ..color = phaseColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(dotX, dotY), strokeWidth / 2 + 2, dotPaint);

      // Dot glow
      final glowPaint = Paint()
        ..color = phaseColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(dotX, dotY), strokeWidth + 4, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CircularTimerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.phaseColor != phaseColor;
  }
}
