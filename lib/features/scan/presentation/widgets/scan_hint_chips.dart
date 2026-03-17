import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ScanHintChips extends StatelessWidget {
  final List<String> hints;

  const ScanHintChips({super.key, required this.hints});

  IconData _getIconForHint(String hint) {
    if (hint.contains('光线')) return Icons.wb_sunny_outlined;
    if (hint.contains('前视') || hint.contains('正视') || hint.contains('自然')) return Icons.face_outlined;
    if (hint.contains('静止') || hint.contains('平稳')) return Icons.accessibility_new_outlined;
    if (hint.contains('平伸') || hint.contains('张口')) return Icons.sentiment_satisfied_alt_outlined;
    if (hint.contains('展开')) return Icons.back_hand_outlined;
    return Icons.check_circle_outline;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: hints.map((hint) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.softBg,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: AppColors.borderColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getIconForHint(hint), size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                hint,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
