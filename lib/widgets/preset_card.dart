import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/workout_config.dart';
import '../theme/app_colors.dart';

class PresetCard extends StatelessWidget {
  final WorkoutConfig config;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final int index;

  const PresetCard({
    super.key,
    required this.config,
    required this.onTap,
    this.onLongPress,
    required this.index,
  });

  IconData get _icon {
    switch (config.name.toLowerCase()) {
      case 'boxe padrão':
        return Icons.sports_mma;
      case 'muay thai':
        return Icons.sports_kabaddi;
      case 'hiit boxing':
        return Icons.flash_on;
      case 'shadow boxing':
        return Icons.directions_run;
      default:
        return Icons.timer;
    }
  }

  Color get _accentColor {
    final colors = [
      AppColors.primary,
      AppColors.restColor,
      AppColors.prepColor,
      AppColors.warningColor,
      AppColors.finishedColor,
      const Color(0xFF00B0FF),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.surface.withValues(alpha: 0.7),
          border: Border.all(
            color: _accentColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon + Name
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_icon, color: _accentColor, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          config.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Stats
                  _StatRow(
                    icon: Icons.repeat,
                    label: '${config.rounds} rounds',
                    color: _accentColor,
                  ),
                  const SizedBox(height: 4),
                  _StatRow(
                    icon: Icons.timer_outlined,
                    label: config.roundDurationFormatted,
                    color: _accentColor,
                  ),
                  const SizedBox(height: 4),
                  _StatRow(
                    icon: Icons.pause_circle_outline,
                    label: '${config.restDurationFormatted} descanso',
                    color: _accentColor,
                  ),

                  const Spacer(),

                  // Total time
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Total: ${config.totalDurationFormatted}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
