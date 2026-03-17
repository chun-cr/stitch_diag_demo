import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../widgets/scan_step_indicator.dart';
import '../widgets/scan_frame.dart';

class TongueScanPage extends StatelessWidget {
  const TongueScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: Center(
                      child: ScanStepIndicator(currentStep: 1),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            
            // Frame
            Expanded(
              child: ScanFrame(
                frameShape: FrameShape.rectangle,
                frameWidth: 220,
                frameHeight: 140,
                themeColor: AppColors.secondary,
                hints: const ['张口自然', '光线充足', '舌头平伸'],
                titleText: '请伸出舌头，保持 2 秒',
                bottomTextIdle: '保持自然表情，正视前方',
                bottomTextScanning: '舌苔颜色正在分析...',
                bottomTextCompleted: '舌头扫描完成 ✓',
                startButtonLabel: '开始舌头扫描',
                nextRoute: AppRoutes.scanPalm,
                nextButtonLabel: '下一步：手掌扫描',
                skipRoute: AppRoutes.scanPalm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
