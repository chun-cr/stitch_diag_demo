import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ScanStepIndicator extends StatelessWidget {
  final int currentStep; // 0: face, 1: tongue, 2: palm

  const ScanStepIndicator({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    const steps = ['面部', '舌头', '手掌'];
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          final stepIndex = index ~/ 2;
          final isActive = currentStep > stepIndex;
          return Container(
            width: 24,
            height: 2,
            margin: const EdgeInsets.only(top: 9, left: 6, right: 6),
            color: isActive ? AppColors.primary : AppColors.borderColor,
          );
        } else {
          final stepIndex = index ~/ 2;
          final isActive = currentStep >= stepIndex;
          final isCurrent = currentStep == stepIndex;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? AppColors.primary : AppColors.cardBg,
                  border: Border.all(
                    color: isActive ? AppColors.primary : AppColors.borderColor,
                    width: 2,
                  ),
                ),
                child: isActive
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 4),
              Text(
                steps[stepIndex],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? AppColors.primary : AppColors.textHint,
                ),
              ),
            ],
          );
        }
      }),
    );
  }
}
