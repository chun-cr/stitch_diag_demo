import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../widgets/scan_step_indicator.dart';
import '../widgets/scan_frame.dart';

class PalmScanPage extends StatelessWidget {
  const PalmScanPage({super.key});

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
                      child: ScanStepIndicator(currentStep: 2),
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
                frameWidth: 200,
                frameHeight: 260,
                themeColor: const Color(0xFF9B8EF0),
                hints: const ['手掌展开', '保持平稳', '光线充足'],
                titleText: '请将手掌展开对准框内',
                bottomTextIdle: '保持自然表情，正视前方',
                bottomTextScanning: '手掌纹路正在识别...',
                bottomTextCompleted: '手掌扫描完成 ✓',
                startButtonLabel: '开始手掌扫描',
                nextRoute: AppRoutes.reportAnalysis,
                nextButtonLabel: '查看分析报告',
                skipRoute: AppRoutes.reportAnalysis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
