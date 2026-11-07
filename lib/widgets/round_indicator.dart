import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RoundIndicator extends StatelessWidget {
  final int totalRounds;
  final int currentRound;
  final Color activeColor;

  const RoundIndicator({
    super.key,
    required this.totalRounds,
    required this.currentRound,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: List.generate(totalRounds, (index) {
        final roundNum = index + 1;
        final isCompleted = roundNum < currentRound;
        final isCurrent = roundNum == currentRound;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: isCurrent ? 32 : 12,
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: isCompleted
                ? activeColor
                : isCurrent
                ? activeColor
                : AppColors.surfaceLight,
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}
